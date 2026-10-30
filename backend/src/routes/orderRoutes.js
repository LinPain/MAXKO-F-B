const express = require('express');
const mongoose = require('mongoose');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const Branch = require('../models/Branch');
const ModifierGroup = require('../models/ModifierGroup');
const Order = require('../models/Order');
const Product = require('../models/Product');
const Voucher = require('../models/Voucher');
const Promotion = require('../models/Promotion');
const Customer = require('../models/Customer');
const CheckoutIdempotency = require('../models/CheckoutIdempotency');
const { isRevoked } = require('../services/accessTokenRevocation');
const { normalizeOrderItems } = require('../services/orderPricingService');

const router = express.Router();
const deliveryFee = Math.max(0, Number(process.env.DELIVERY_FEE || 0));
const success = (res, data, message) => res.json({ success: true, ...(message ? { message } : {}), data });

async function optionalCustomer(req) {
  const token = req.headers.authorization?.replace(/^Bearer\s+/i, '');
  if (!token) return null;
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    if (isRevoked(payload.jti)) {
      const error = new Error('Phiên làm việc đã kết thúc. Đăng nhập lại để tiếp tục.');
      error.statusCode = 401;
      error.code = 'SESSION_REVOKED';
      throw error;
    }
    return await Customer.findById(payload.sub);
  } catch (_) {
    const error = new Error('Phiên làm việc hết hạn.');
    error.statusCode = 401;
    error.code = 'UNAUTHORIZED';
    throw error;
  }
}

function customerDetails(body) {
  const name = String(body.customerName || '').trim();
  const phone = String(body.customerPhone || '').trim();
  if (!name || name.length > 100 || !/^\+?[0-9 .()-]{8,20}$/.test(phone)) {
    const error = new Error('Vui lòng nhập tên và số điện thoại hợp lệ.');
    error.statusCode = 400;
    error.code = 'CUSTOMER_INFO_INVALID';
    throw error;
  }
  return { name, phone };
}

function coordinatesOf(body) {
  const value = body.deliveryCoordinates || {};
  const lat = Number(value.lat ?? value.latitude ?? body.latitude ?? body.customerLat);
  const lng = Number(value.lng ?? value.longitude ?? body.longitude ?? body.customerLng);
  if (!Number.isFinite(lat) || lat < -90 || lat > 90 || !Number.isFinite(lng) || lng < -180 || lng > 180) return null;
  return { lat, lng };
}

function distanceKm(lat1, lng1, lat2, lng2) {
  const radians = (value) => value * Math.PI / 180;
  const dLat = radians(lat2 - lat1);
  const dLng = radians(lng2 - lng1);
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(radians(lat1)) * Math.cos(radians(lat2)) * Math.sin(dLng / 2) ** 2;
  return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function stableStringify(value) {
  if (Array.isArray(value)) return `[${value.map(stableStringify).join(',')}]`;
  if (value && typeof value === 'object') {
    return `{${Object.keys(value).filter((key) => key !== 'idempotencyKey').sort().map((key) => `${JSON.stringify(key)}:${stableStringify(value[key])}`).join(',')}}`;
  }
  return JSON.stringify(value);
}

function requestDigest(body) {
  return crypto.createHash('sha256').update(stableStringify(body)).digest('hex');
}

async function branchById(id, brandId = '') {
  const branch = await Branch.findOne({ id: String(id), isActive: true }).lean();
  if (!branch) {
    const error = new Error(`Không tìm thấy cơ sở ${id}.`);
    error.statusCode = 400;
    error.code = 'BRANCH_NOT_FOUND';
    throw error;
  }
  if (!branch.isOpen) {
    const error = new Error(`${branch.name} hiện đã đóng cửa.`);
    error.statusCode = 400;
    error.code = 'BRANCH_CLOSED';
    throw error;
  }
  if (brandId && branch.brandIds?.length && !branch.brandIds.includes(brandId)) {
    const error = new Error(`${branch.name} không phục vụ thương hiệu đã chọn.`);
    error.statusCode = 400;
    error.code = 'BRAND_NOT_AT_BRANCH';
    throw error;
  }
  return branch;
}

function validateDelivery(branch, coordinates) {
  if (!coordinates) {
    const error = new Error('Đơn giao hàng cần tọa độ hợp lệ.');
    error.statusCode = 400;
    error.code = 'DELIVERY_COORDINATES_REQUIRED';
    throw error;
  }
  const distance = distanceKm(branch.latitude, branch.longitude, coordinates.lat, coordinates.lng);
  const maxDistance = Number(process.env.MAX_DELIVERY_DISTANCE_KM || 4);
  if (distance > maxDistance) {
    const error = new Error(`Khoảng cách ${distance.toFixed(2)} km vượt quá bán kính giao hàng ${maxDistance} km.`);
    error.statusCode = 400;
    error.code = 'DELIVERY_OUT_OF_RANGE';
    error.data = { isValid: false, distanceKm: Number(distance.toFixed(2)), maxDistanceKm: maxDistance };
    throw error;
  }
  return Number(distance.toFixed(2));
}

async function priceGroup(group) {
  const items = Array.isArray(group.items) ? group.items : [];
  if (!items.length) {
    const error = new Error('Mỗi đơn nhóm phải có ít nhất một món.');
    error.statusCode = 400;
    error.code = 'EMPTY_ORDER';
    throw error;
  }
  const ids = [...new Set(items.map((item) => String(item.productId || '')))];
  if (ids.some((id) => !/^[a-zA-Z0-9_-]{2,100}$/.test(id))) {
    const error = new Error('Mã sản phẩm không hợp lệ.');
    error.statusCode = 400;
    error.code = 'PRODUCT_UNAVAILABLE';
    throw error;
  }
  const objectIds = ids.filter((id) => mongoose.isValidObjectId(id));
  const products = await Product.find({ isAvailable: true, $or: [
    { _id: { $in: objectIds } },
    { id: { $in: ids } },
  ] }).lean();
  const modifierGroups = await ModifierGroup.find({ brandId: String(group.brandId || 'brand-legia'), isActive: true }).lean();
  const priced = normalizeOrderItems(items, products, {
    branchId: String(group.branchId || ''),
    brandId: String(group.brandId || 'brand-legia'),
    modifierGroups,
  });
  return { ...group, items: priced.normalizedItems, subtotal: priced.subtotal };
}

async function getVoucherDiscount(code, subtotal, { customerId = null, brandId = '', branchId = '', items = [] } = {}) {
  if (!code) return { voucher: null, discount: 0 };
  const normalizedCode = String(code).trim().toUpperCase();
  const voucher = await Voucher.findOne({ code: normalizedCode, isActive: true }).lean();
  const now = new Date();
  const eligible = voucher &&
    (!voucher.ownerCustomer || String(voucher.ownerCustomer) === String(customerId || '')) &&
    subtotal >= Number(voucher.minOrderTotal || 0) &&
    (!voucher.startDate || voucher.startDate <= now) &&
    (!voucher.endDate || voucher.endDate >= now) &&
    (!voucher.brandIds?.length || voucher.brandIds.includes(brandId)) &&
    (!voucher.branchIds?.length || voucher.branchIds.includes(branchId)) &&
    !voucher.usedAt;
  if (eligible) {
    const raw = voucher.discountAmount || subtotal * Number(voucher.discountPercent || 0) / 100;
    return { voucher, discount: Math.round(Math.min(raw, voucher.maxDiscount || Number.MAX_SAFE_INTEGER, subtotal)) };
  }
  if (!voucher) {
    const promotion = await Promotion.findOne({ code: normalizedCode, isActive: true }).lean();
    const promotionEligible = promotion &&
      (!promotion.startDate || promotion.startDate <= now) &&
      (!promotion.endDate || promotion.endDate >= now) &&
      subtotal >= Number(promotion.minOrderTotal || 0) &&
      (!promotion.brandIds?.length || promotion.brandIds.includes(brandId)) &&
      (!promotion.branchIds?.length || promotion.branchIds.includes(branchId)) &&
      (!promotion.productIds?.length || items.some((item) => promotion.productIds.includes(String(item.productId))));
    if (promotionEligible) {
      const eligibleSubtotal = promotion.productIds?.length
        ? items.filter((item) => promotion.productIds.includes(String(item.productId))).reduce((sum, item) => sum + Number(item.totalPrice || 0), 0)
        : subtotal;
      const raw = promotion.type === 'PERCENT' ? eligibleSubtotal * Number(promotion.value || 0) / 100 : Number(promotion.value || 0);
      return { voucher: { code: promotion.code, title: promotion.title, source: 'PROMOTION' }, discount: Math.round(Math.min(raw, promotion.maxDiscount || Number.MAX_SAFE_INTEGER, subtotal)) };
    }
  }
  if (!eligible) {
    const error = new Error('Voucher không hợp lệ hoặc không đủ điều kiện áp dụng.');
    error.statusCode = 400;
    error.code = 'VOUCHER_INVALID';
    throw error;
  }
  const raw = voucher.discountAmount || subtotal * Number(voucher.discountPercent || 0) / 100;
  return { voucher, discount: Math.min(raw, voucher.maxDiscount || Number.MAX_SAFE_INTEGER, subtotal) };
}

function formatBranch(branch) {
  return {
    ...branch,
    latitude: branch.latitude,
    longitude: branch.longitude,
    gps: { latitude: branch.latitude, longitude: branch.longitude },
  };
}

router.post('/precheck', async (req, res, next) => {
  try {
    const coordinates = coordinatesOf(req.body);
    const hasDeliveryContext = Boolean(String(req.body.deliveryAddress || '').trim() || coordinates);
    const type = String(req.body.orderType || (hasDeliveryContext ? 'DELIVERY' : 'TAKEAWAY')).toUpperCase();
    if (!['DELIVERY', 'TAKEAWAY', 'DINE_IN'].includes(type)) return res.status(400).json({ success: false, error: 'Hình thức nhận hàng không hợp lệ.', code: 'INVALID_ORDER_TYPE' });
    if (type === 'DELIVERY' && !String(req.body.deliveryAddress || '').trim()) return res.status(400).json({ success: false, error: 'Thiếu địa chỉ giao hàng.', code: 'DELIVERY_ADDRESS_REQUIRED' });
    const groups = new Map();
    for (const item of req.body.items || []) {
      const key = `${item.branchId || req.body.branchId || ''}|${item.brandId || req.body.brandId || 'brand-legia'}`;
      groups.set(key, [...(groups.get(key) || []), item]);
    }
    if (!groups.size) return res.status(400).json({ success: false, error: 'Giỏ hàng đang trống.', code: 'EMPTY_ORDER' });
    const deliveryCoordinates = type === 'DELIVERY' ? coordinates : null;
    let subtotal = 0;
    let itemCount = 0;
    for (const [key, items] of groups) {
      const [branchId, brandId] = key.split('|');
      const branch = await branchById(branchId, brandId);
      if (type === 'DELIVERY') validateDelivery(branch, deliveryCoordinates);
      const priced = await priceGroup({ branchId, brandId, items });
      subtotal += priced.subtotal;
      itemCount += priced.items.length;
    }
    success(res, { isValid: true, subtotal, itemCount, deliveryFee: type === 'DELIVERY' ? deliveryFee : 0 });
  } catch (error) { next(error); }
});

router.post('/check-stock', async (req, res, next) => {
  try {
    const branchId = String(req.body.branchId || '');
    const branch = await branchById(branchId);
    const items = Array.isArray(req.body.items) ? req.body.items : [];
    const outOfStockItems = [];
    for (const item of items) {
      const productId = String(item.productId || '');
      if (!/^[a-zA-Z0-9_-]{2,100}$/.test(productId)) {
        outOfStockItems.push({ itemId: item.productId || '', productName: item.productName || '', reason: 'Mã sản phẩm không hợp lệ.' });
        continue;
      }
      const product = mongoose.isValidObjectId(productId)
        ? await Product.findOne({ $or: [{ _id: productId }, { id: productId }] }).lean()
        : await Product.findOne({ id: productId }).lean();
      const available = product?.isAvailable !== false && product && product.branchAvailability?.[branchId] !== false;
      if (!available) outOfStockItems.push({ itemId: item.productId, productName: product?.name || item.productName || '', reason: 'Món hiện không khả dụng tại cơ sở này.' });
    }
    const available = outOfStockItems.length === 0;
    success(res, {
      available,
      isAvailable: available,
      canFulfillOrder: available,
      branchId: branch.id,
      branchName: branch.name,
      totalItems: items.length,
      outOfStockCount: outOfStockItems.length,
      outOfStockItems,
      inventoryCheck: 'PRODUCT_AVAILABILITY_ONLY',
    }, available ? 'Các món đang được bật bán tại cơ sở.' : `Có ${outOfStockItems.length} món không khả dụng.`);
  } catch (error) { next(error); }
});

router.post('/batch-checkout', async (req, res, next) => {
  let idempotencyRecord = null;
  let ordersCreated = false;
  let idempotencyKey = '';
  let idempotencyScope = '';
  let payloadHash = '';
  try {
    const customer = await optionalCustomer(req);
    const { name, phone } = customerDetails(req.body);
    idempotencyKey = String(req.get('Idempotency-Key') || req.body.idempotencyKey || '').trim();
    if (idempotencyKey) {
      if (idempotencyKey.length > 128) return res.status(400).json({ success: false, error: 'Idempotency-Key quá dài.', message: 'Idempotency-Key quá dài.', code: 'INVALID_IDEMPOTENCY_KEY' });
      payloadHash = requestDigest(req.body);
      idempotencyScope = customer ? `customer:${customer.id}` : `guest:${crypto.createHash('sha256').update(phone).digest('hex')}`;
      const previous = await CheckoutIdempotency.findOne({ scope: idempotencyScope, key: idempotencyKey }).lean();
      if (previous) {
        if (previous.requestHash !== payloadHash) return res.status(409).json({ success: false, error: 'Idempotency-Key đã được dùng với nội dung khác.', message: 'Idempotency-Key đã được dùng với nội dung khác.', code: 'IDEMPOTENCY_KEY_REUSED' });
        if (previous.state === 'COMPLETED' && previous.response) return res.status(201).json(previous.response);
        res.setHeader('Retry-After', '2');
        return res.status(409).json({ success: false, error: 'Đơn hàng với khóa này đang được xử lý.', message: 'Đơn hàng với khóa này đang được xử lý.', code: 'CHECKOUT_IN_PROGRESS' });
      }
    }
    const orderType = String(req.body.orderType || 'TAKEAWAY').toUpperCase();
    if (!['DELIVERY', 'TAKEAWAY', 'DINE_IN'].includes(orderType)) {
      return res.status(400).json({ success: false, error: 'Hình thức nhận hàng không hợp lệ.', code: 'INVALID_ORDER_TYPE' });
    }
    if (orderType === 'DELIVERY' && !String(req.body.deliveryAddress || '').trim()) {
      return res.status(400).json({ success: false, error: 'Thiếu địa chỉ giao hàng.', code: 'DELIVERY_ADDRESS_REQUIRED' });
    }
    const paymentMethod = String(req.body.paymentMethod || 'CASH').toUpperCase();
    if (paymentMethod !== 'CASH') return res.status(503).json({ success: false, error: 'Thanh toán trực tuyến chưa được cấu hình. Chọn tiền mặt khi nhận đơn.', message: 'Thanh toán trực tuyến chưa được cấu hình. Chọn tiền mặt khi nhận đơn.', code: 'PAYMENT_METHOD_UNAVAILABLE' });

    const inputGroups = Array.isArray(req.body.groupedOrders)
      ? req.body.groupedOrders
      : Array.isArray(req.body.orders) ? req.body.orders : [];
    if (!inputGroups.length) return res.status(400).json({ success: false, error: 'Đơn hàng chưa có món.', code: 'EMPTY_ORDER' });
    const coordinates = orderType === 'DELIVERY' ? coordinatesOf(req.body) : null;
    const pricedGroups = [];
    for (const group of inputGroups) {
      const brandId = String(group.brandId || 'brand-legia');
      const branch = await branchById(group.branchId, brandId);
      if (orderType === 'DELIVERY') validateDelivery(branch, coordinates);
      pricedGroups.push({ ...(await priceGroup({ ...group, brandId })), branch });
    }

    const subtotal = pricedGroups.reduce((sum, group) => sum + group.subtotal, 0);
    const brandIds = [...new Set(pricedGroups.map((group) => group.brandId))];
    const branchIds = [...new Set(pricedGroups.map((group) => group.branchId))];
    const { voucher, discount } = await getVoucherDiscount(req.body.voucherCode, subtotal, {
      customerId: customer?._id,
      brandId: brandIds.length === 1 ? brandIds[0] : '',
      branchId: branchIds.length === 1 ? branchIds[0] : '',
      items: pricedGroups.flatMap((group) => group.items),
    });
    const shipping = orderType === 'DELIVERY' ? deliveryFee : 0;
    const batchId = `batch-${crypto.randomBytes(12).toString('hex')}`;
    let remainingDiscount = discount;
    const documents = pricedGroups.map((group, index) => {
      const groupDiscount = index === pricedGroups.length - 1
        ? Math.min(remainingDiscount, group.subtotal)
        : Math.min(discount * group.subtotal / subtotal, group.subtotal);
      remainingDiscount -= groupDiscount;
      const groupShipping = orderType === 'DELIVERY' && index === 0 ? shipping : 0;
      return {
        batchId,
        brandId: group.brandId,
        customer: customer?._id || null,
        branchId: group.branchId,
        branchName: group.branch.name,
        orderType,
        source: 'APP',
        customerName: name,
        customerPhone: phone,
        deliveryAddress: String(req.body.deliveryAddress || '').trim(),
        deliveryCoordinates: orderType === 'DELIVERY' ? coordinates : undefined,
        note: String(req.body.note || '').trim(),
        items: group.items,
        subtotal: group.subtotal,
        discount: groupDiscount,
        shippingFee: groupShipping,
        finalTotal: group.subtotal - groupDiscount + groupShipping,
        paymentMethod,
        paymentStatus: 'UNPAID',
        status: 'PENDING',
        voucherCode: voucher?.code || '',
        statusTimeline: [{ status: 'PENDING', time: new Date() }],
      };
    });
    if (idempotencyKey) {
      try {
        idempotencyRecord = await CheckoutIdempotency.create({ scope: idempotencyScope, key: idempotencyKey, requestHash: payloadHash, expiresAt: new Date(Date.now() + 86400000) });
      } catch (error) {
        if (error.code !== 11000) throw error;
        const concurrent = await CheckoutIdempotency.findOne({ scope: idempotencyScope, key: idempotencyKey }).lean();
        if (concurrent?.requestHash !== payloadHash) return res.status(409).json({ success: false, error: 'Idempotency-Key đã được dùng với nội dung khác.', message: 'Idempotency-Key đã được dùng với nội dung khác.', code: 'IDEMPOTENCY_KEY_REUSED' });
        if (concurrent?.state === 'COMPLETED' && concurrent.response) return res.status(201).json(concurrent.response);
        res.setHeader('Retry-After', '2');
        return res.status(409).json({ success: false, error: 'Đơn hàng với khóa này đang được xử lý.', message: 'Đơn hàng với khóa này đang được xử lý.', code: 'CHECKOUT_IN_PROGRESS' });
      }
    }
    let claimedVoucher = false;
    if (voucher?.ownerCustomer && customer) {
      const claim = await Voucher.findOneAndUpdate(
        { _id: voucher._id, ownerCustomer: customer._id, isActive: true, usedAt: null },
        { $set: { usedAt: new Date(), isActive: false } },
        { new: true },
      );
      if (!claim) {
        const error = new Error('Voucher đã được sử dụng hoặc không còn khả dụng.');
        error.statusCode = 409;
        error.code = 'VOUCHER_ALREADY_USED';
        throw error;
      }
      claimedVoucher = true;
    }
    let orders;
    try {
      orders = await Order.insertMany(documents, { ordered: true });
    } catch (error) {
      await Order.deleteMany({ batchId });
      if (claimedVoucher) await Voucher.updateOne({ _id: voucher._id }, { $set: { usedAt: null, isActive: true } });
      throw error;
    }
    ordersCreated = true;
    const data = orders.map((order) => ({
      id: String(order._id),
      orderNumber: order.orderNumber,
      batchId,
      branchId: order.branchId,
      branchName: order.branchName,
      brandId: order.brandId,
      orderType: order.orderType,
      items: order.items,
      subtotal: order.subtotal,
      discount: order.discount,
      shippingFee: order.shippingFee,
      total: order.finalTotal,
      finalTotal: order.finalTotal,
      paymentMethod: order.paymentMethod,
      paymentStatus: order.paymentStatus,
      status: order.status,
      createdAt: order.createdAt,
    }));
    const response = {
      success: true,
      message: 'Đơn hàng đã được gửi tới MAXKO.',
      data: {
        batchId,
        orders: data,
        subtotal,
        discount,
        shippingFee: shipping,
        total: Math.max(0, subtotal - discount + shipping),
      },
    };
    if (idempotencyRecord) {
      idempotencyRecord.state = 'COMPLETED';
      idempotencyRecord.response = response;
      await idempotencyRecord.save();
    }
    res.status(201).json(response);
  } catch (error) {
    if (idempotencyRecord && !ordersCreated) await idempotencyRecord.deleteOne().catch(() => {});
    next(error);
  }
});

router.get('/batch/:batchId', async (req, res, next) => {
  try {
    const orders = await Order.find({ batchId: req.params.batchId }).sort({ createdAt: 1 }).lean();
    if (!orders.length) return res.status(404).json({ success: false, error: 'Không tìm thấy phiên đơn hàng.', code: 'BATCH_NOT_FOUND' });
    const subtotal = orders.reduce((sum, order) => sum + Number(order.subtotal || 0), 0);
    const discount = orders.reduce((sum, order) => sum + Number(order.discount || 0), 0);
    const shippingFee = orders.reduce((sum, order) => sum + Number(order.shippingFee || 0), 0);
    success(res, {
      batchId: req.params.batchId,
      orders: orders.map((order) => ({ ...order, id: String(order._id), total: order.finalTotal })),
      subtotal,
      discount,
      shippingFee,
      total: subtotal - discount + shippingFee,
    });
  } catch (error) { next(error); }
});

module.exports = router;
