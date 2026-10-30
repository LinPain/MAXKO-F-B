const express = require('express');
const crypto = require('crypto');
const mongoose = require('mongoose');
const Customer = require('../models/Customer');
const LuckyWheelConfig = require('../models/LuckyWheelConfig');
const LuckyWheelDailyUsage = require('../models/LuckyWheelDailyUsage');
const LuckyWheelSpin = require('../models/LuckyWheelSpin');
const Promotion = require('../models/Promotion');
const Voucher = require('../models/Voucher');
const Product = require('../models/Product');
const requireAuth = require('../middleware/requireAuth');

const router = express.Router();
const success = (res, data, message) => res.json({ success: true, ...(message ? { message } : {}), data });
const idOf = (doc) => String(doc._id || doc.id);

function dayKey(date = new Date()) {
  const zone = process.env.APP_TIMEZONE || 'Asia/Bangkok';
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: zone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(date);
  const values = Object.fromEntries(parts.map((part) => [part.type, part.value]));
  return `${values.year}-${values.month}-${values.day}`;
}

function spinsForTier(config, tier) {
  const limits = config.spinsPerDayByTier instanceof Map
    ? Object.fromEntries(config.spinsPerDayByTier)
    : config.spinsPerDayByTier || {};
  const normalized = String(tier || 'BRONZE').toUpperCase();
  const aliases = { STANDARD: 'BRONZE', DIAMOND: 'PLATINUM' };
  const value = limits[normalized] ?? limits[aliases[normalized]] ?? limits.BRONZE ?? 0;
  return Math.max(0, Math.min(20, Number(value) || 0));
}

async function loadWheelState(customer) {
  const config = await LuckyWheelConfig.findOne({ key: 'default', isActive: true }).lean();
  if (!config) return null;
  const today = dayKey();
  const allowed = spinsForTier(config, customer?.membershipTier);
  const usage = customer
    ? await LuckyWheelDailyUsage.findOne({ customer: customer._id, dayKey: today }).lean()
    : null;
  const used = Number(usage?.spins || 0);
  return { config, today, allowed, used, remaining: Math.max(0, allowed - used) };
}

router.get('/promotions', async (req, res, next) => {
  try {
    const now = new Date();
    const filter = { isActive: true, $and: [
      { $or: [{ startDate: null }, { startDate: { $lte: now } }] },
      { $or: [{ endDate: null }, { endDate: { $gte: now } }] },
    ] };
    if (req.query.brandId) filter.$and.push({ $or: [{ brandIds: { $size: 0 } }, { brandIds: String(req.query.brandId) }] });
    const promotions = await Promotion.find(filter).sort({ startDate: 1 }).lean();
    success(res, promotions.map((item) => ({
      id: idOf(item),
      code: item.code || '',
      title: item.title,
      description: item.description,
      type: item.type,
      value: item.value,
      maxDiscount: item.maxDiscount,
      minOrderTotal: item.minOrderTotal,
      startDate: item.startDate,
      endDate: item.endDate,
    })));
  } catch (error) { next(error); }
});

router.get('/promotions/:id', async (req, res, next) => {
  try {
    const promotion = await Promotion.findOne({ $or: [{ _id: req.params.id }, { code: req.params.id.toUpperCase() }], isActive: true }).lean();
    if (!promotion) return res.status(404).json({ success: false, error: 'Không tìm thấy chương trình.', code: 'PROMOTION_NOT_FOUND' });
    success(res, { id: idOf(promotion), code: promotion.code || '', title: promotion.title, description: promotion.description, type: promotion.type, value: promotion.value, maxDiscount: promotion.maxDiscount, minOrderTotal: promotion.minOrderTotal, startDate: promotion.startDate, endDate: promotion.endDate });
  } catch (error) { next(error); }
});

router.post('/promotions/evaluate', async (req, res, next) => {
  try {
    const items = Array.isArray(req.body.items) ? req.body.items : [];
    if (!items.length) return res.status(400).json({ success: false, error: 'Cần có món hàng để đánh giá ưu đãi.', code: 'EMPTY_ORDER' });
    const productIds = [...new Set(items.map((item) => String(item.productId || '')))];
    if (productIds.some((id) => !/^[a-zA-Z0-9_-]{2,100}$/.test(id))) return res.status(400).json({ success: false, error: 'Mã sản phẩm không hợp lệ.', code: 'PRODUCT_UNAVAILABLE' });
    const objectIds = productIds.filter((id) => mongoose.isValidObjectId(id));
    const products = await Product.find({ isAvailable: true, $or: [
      { _id: { $in: objectIds } },
      { id: { $in: productIds } },
    ] }).lean();
    const productsByKey = new Map();
    for (const product of products) {
      productsByKey.set(String(product._id), product);
      if (product.id) productsByKey.set(String(product.id), product);
    }
    const requestedBrand = String(req.body.brandId || '');
    const brandIds = [...new Set(products.map((product) => String(product.brandId || 'brand-legia')))];
    const brandId = requestedBrand || (brandIds.length === 1 ? brandIds[0] : '');
    const branchId = String(req.body.branchId || '');
    const pricedItems = items.map((item) => {
      const product = productsByKey.get(String(item.productId));
      const quantity = Number(item.quantity);
      if (!product || (branchId && product.branchAvailability?.[branchId] === false)) {
        const error = new Error(`Sản phẩm không khả dụng: ${item.productName || item.productId}`);
        error.statusCode = 400;
        error.code = 'PRODUCT_UNAVAILABLE';
        throw error;
      }
      if (brandId && product.brandId && product.brandId !== brandId) {
        const error = new Error('Sản phẩm không thuộc thương hiệu đã chọn.');
        error.statusCode = 400;
        error.code = 'PRODUCT_BRAND_MISMATCH';
        throw error;
      }
      if (!Number.isInteger(quantity) || quantity < 1 || quantity > 99) {
        const error = new Error('Số lượng mỗi món phải từ 1 đến 99.');
        error.statusCode = 400;
        error.code = 'INVALID_QUANTITY';
        throw error;
      }
      const override = product.branchPriceOverrides instanceof Map
        ? product.branchPriceOverrides.get(branchId)
        : product.branchPriceOverrides?.[branchId];
      const unitPrice = Number(override ?? product.basePrice ?? product.price ?? 0);
      return { productId: String(product.id || product._id), quantity, totalPrice: unitPrice * quantity };
    });
    // orderAmount is accepted by the legacy request shape but never used as a price source.
    const orderTotal = pricedItems.reduce((sum, item) => sum + item.totalPrice, 0);
    const now = new Date();
    const candidates = await Promotion.find({ isActive: true, $and: [
      { $or: [{ startDate: null }, { startDate: { $lte: now } }] },
      { $or: [{ endDate: null }, { endDate: { $gte: now } }] },
      { $or: [{ brandIds: { $size: 0 } }, { brandIds: brandId }] },
      { $or: [{ branchIds: { $size: 0 } }, { branchIds: branchId }] },
    ] }).lean();
    const code = String(req.body.code || '').trim().toUpperCase();
    let voucher = null;
    if (code) {
      voucher = await Voucher.findOne({ code, isActive: true, usedAt: null }).lean();
      if (voucher && voucher.ownerCustomer) voucher = null;
    }
    const promos = [...candidates];
    if (voucher && (!voucher.brandIds?.length || voucher.brandIds.includes(brandId)) && orderTotal >= Number(voucher.minOrderTotal || 0) && (!voucher.startDate || voucher.startDate <= now) && (!voucher.endDate || voucher.endDate >= now)) {
      promos.push({ code: voucher.code, title: voucher.title || voucher.code, type: voucher.discountPercent ? 'PERCENT' : 'FIXED', value: voucher.discountPercent || voucher.discountAmount, maxDiscount: voucher.maxDiscount, minOrderTotal: voucher.minOrderTotal, productIds: [] });
    }
    const eligible = promos.filter((promotion) => {
      if (orderTotal < Number(promotion.minOrderTotal || 0)) return false;
      if (promotion.productIds?.length && !pricedItems.some((item) => promotion.productIds.includes(String(item.productId)))) return false;
      return true;
    }).map((promotion) => {
      const itemTotal = promotion.productIds?.length
        ? pricedItems.filter((item) => promotion.productIds.includes(String(item.productId))).reduce((sum, item) => sum + Number(item.totalPrice || 0), 0)
        : orderTotal;
      const raw = promotion.type === 'PERCENT' ? itemTotal * Number(promotion.value || 0) / 100 : Number(promotion.value || 0);
      const amount = Math.max(0, Math.min(raw, Number(promotion.maxDiscount || Number.MAX_SAFE_INTEGER), orderTotal));
      return { promotion, amount };
    }).filter((item) => item.amount > 0).sort((a, b) => b.amount - a.amount);
    const best = eligible[0];
    success(res, {
      discountAmount: best?.amount || 0,
      finalTotal: Math.max(0, orderTotal - (best?.amount || 0)),
      appliedCampaign: best ? { id: idOf(best.promotion), code: best.promotion.code || '', title: best.promotion.title, discountAmount: best.amount } : null,
      eligibleCount: eligible.length,
    }, best ? 'Áp dụng thành công.' : 'Không có chương trình phù hợp.');
  } catch (error) { next(error); }
});

router.get('/marketing/lucky-wheel/config', async (req, res, next) => {
  try {
    const customer = req.headers.authorization ? await (async () => {
      const token = req.headers.authorization.replace(/^Bearer\s+/i, '');
      const jwt = require('jsonwebtoken');
      const Customer = require('../models/Customer');
      const payload = jwt.verify(token, process.env.JWT_SECRET);
      return Customer.findById(payload.sub);
    })() : null;
    const state = await loadWheelState(customer);
    if (!state) return res.status(503).json({ success: false, error: 'Vòng quay hiện chưa được cấu hình.', code: 'LUCKY_WHEEL_UNAVAILABLE' });
    success(res, {
      id: idOf(state.config),
      title: state.config.title,
      prizes: (state.config.prizes || []).map(({ id, label, rewardType }) => ({ id, label, rewardType })),
      membershipTier: customer?.membershipTier || null,
      spinsAllowedToday: state.allowed,
      spinsUsedToday: state.used,
      spinsRemaining: state.remaining,
      requiresLoginToSpin: true,
    });
  } catch (error) { next(error); }
});

function choosePrize(prizes) {
  const scale = 10000;
  const weighted = prizes.map((prize) => ({ prize, weight: Math.max(0, Math.round(Number(prize.probability || 0) * scale)) }));
  const total = weighted.reduce((sum, item) => sum + item.weight, 0);
  if (!total) throw new Error('Vòng quay chưa có xác suất trúng hợp lệ.');
  let selection = crypto.randomInt(total);
  for (const item of weighted) {
    if (selection < item.weight) return item.prize;
    selection -= item.weight;
  }
  return weighted[weighted.length - 1].prize;
}

async function reserveSpin(customer, day, limit) {
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const usage = await LuckyWheelDailyUsage.findOneAndUpdate(
        { customer: customer._id, dayKey: day, spins: { $lt: limit } },
        { $inc: { spins: 1 }, $setOnInsert: { customer: customer._id, dayKey: day } },
        { new: true, upsert: true, setDefaultsOnInsert: true },
      );
      return usage;
    } catch (error) {
      if (error.code !== 11000) throw error;
    }
  }
  return null;
}

router.post('/marketing/lucky-wheel/spin', requireAuth, async (req, res, next) => {
  let reserved = false;
  let reservedDay = null;
  let spin = null;
  let voucher = null;
  let pointsAwarded = 0;
  try {
    const customer = req.customer;
    const state = await loadWheelState(customer);
    if (!state || !state.config.prizes?.length) return res.status(503).json({ success: false, error: 'Vòng quay hiện chưa được cấu hình.', code: 'LUCKY_WHEEL_UNAVAILABLE' });
    if (state.allowed <= 0) return res.status(403).json({ success: false, error: 'Hạng thành viên của bạn chưa có lượt quay.', code: 'NO_SPINS_AVAILABLE' });
    const usage = await reserveSpin(customer, state.today, state.allowed);
    if (!usage) return res.status(429).json({ success: false, error: 'Bạn đã dùng hết lượt quay hôm nay.', code: 'DAILY_SPIN_LIMIT_REACHED', data: { spinsRemaining: 0 } });
    reserved = true;
    reservedDay = state.today;

    const prize = choosePrize(state.config.prizes);
    const voucherCode = prize.rewardType === 'VOUCHER' ? `MK${crypto.randomBytes(5).toString('hex').toUpperCase()}` : '';
    spin = await LuckyWheelSpin.create({
      customer: customer._id,
      prizeId: prize.id,
      prizeLabel: prize.label,
      rewardType: prize.rewardType,
      dayKey: state.today,
    });
    if (prize.rewardType === 'POINTS' && Number(prize.points) > 0) {
      pointsAwarded = Number(prize.points);
      await Customer.updateOne({ _id: customer._id }, {
        $inc: { loyaltyPoints: pointsAwarded },
        $push: { pointsHistory: { date: new Date(), description: `Thưởng vòng quay: ${prize.label}`, points: pointsAwarded } },
      });
    } else if (prize.rewardType === 'VOUCHER') {
      const expiresAt = new Date(Date.now() + Math.max(1, Number(prize.voucherValidityDays || 30)) * 86400000);
      voucher = await Voucher.create({
        code: voucherCode,
        title: prize.label,
        discountPercent: Number(prize.discountPercent || 0),
        discountAmount: Number(prize.discountAmount || 0),
        maxDiscount: Number(prize.maxDiscount || 0),
        minOrderTotal: Number(prize.minOrderTotal || 0),
        ownerCustomer: customer._id,
        source: 'LUCKY_WHEEL',
        startDate: new Date(),
        endDate: expiresAt,
        isActive: true,
      });
    }
    spin.voucherCode = voucher?.code || '';
    spin.pointsAwarded = pointsAwarded;
    await spin.save();

    const latestUsage = await LuckyWheelDailyUsage.findOne({ customer: customer._id, dayKey: state.today }).lean();
    const index = state.config.prizes.findIndex((item) => item.id === prize.id);
    success(res, {
      spinId: idOf(spin),
      prizeId: prize.id,
      prizeIndex: index,
      prize: { id: prize.id, label: prize.label, rewardType: prize.rewardType },
      pointsAwarded,
      loyaltyPoints: Number(customer.loyaltyPoints || 0) + pointsAwarded,
      voucher: voucher ? { code: voucher.code, title: voucher.title, endDate: voucher.endDate } : null,
      spinsRemaining: Math.max(0, state.allowed - Number(latestUsage?.spins || 0)),
    }, 'Lượt quay thành công.');
  } catch (error) {
    if (spin) await LuckyWheelSpin.deleteOne({ _id: spin._id }).catch(() => {});
    if (voucher) await Voucher.deleteOne({ _id: voucher._id }).catch(() => {});
    if (pointsAwarded) await Customer.updateOne({ _id: req.customer._id }, { $inc: { loyaltyPoints: -pointsAwarded }, $pull: { pointsHistory: { description: `Thưởng vòng quay: ${spin?.prizeLabel || ''}` } } }).catch(() => {});
    if (reserved && reservedDay) await LuckyWheelDailyUsage.updateOne({ customer: req.customer._id, dayKey: reservedDay }, { $inc: { spins: -1 } }).catch(() => {});
    next(error);
  }
});

router.get('/marketing/lucky-wheel/history', requireAuth, async (req, res, next) => {
  try {
    const history = await LuckyWheelSpin.find({ customer: req.customer._id }).sort({ createdAt: -1 }).limit(100).lean();
    success(res, history.map((item) => ({
      id: String(item._id),
      prizeId: item.prizeId,
      prizeLabel: item.prizeLabel,
      rewardType: item.rewardType,
      pointsAwarded: item.pointsAwarded,
      voucherCode: item.voucherCode,
      createdAt: item.createdAt,
    })));
  } catch (error) { next(error); }
});

module.exports = router;
