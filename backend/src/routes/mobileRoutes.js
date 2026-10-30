const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const mongoose = require('mongoose');
const nodemailer = require('nodemailer');
const Customer = require('../models/Customer');
const SignupEmailVerification = require('../models/SignupEmailVerification');
const Order = require('../models/Order');
const Voucher = require('../models/Voucher');
const Notification = require('../models/Notification');
const Product = require('../models/Product');
const Branch = require('../models/Branch');
const ModifierGroup = require('../models/ModifierGroup');
const Reward = require('../models/Reward');
const Promotion = require('../models/Promotion');
const { normalizeOrderItems } = require('../services/orderPricingService');
const requireAuth = require('../middleware/requireAuth');
const { revoke } = require('../services/accessTokenRevocation');
const optionalAuth = async (req, res, next) => {
  if (!req.headers.authorization) return next();
  return requireAuth(req, res, next);
};

const router = express.Router();
const hash = (token) => crypto.createHash('sha256').update(token).digest('hex');
const safeCustomer = (customer) => ({ id: customer.id, name: customer.name, phone: customer.phone, email: customer.email, birthday: customer.birthday || null, gender: customer.gender || 'unspecified', role: customer.role, membershipTier: customer.membershipTier, loyaltyPoints: customer.loyaltyPoints });
const success = (res, data, message) => res.json({ success: true, ...(message ? { message } : {}), data });
async function issueTokens(customer) {
  const refreshToken = crypto.randomBytes(48).toString('hex');
  const configuredRefreshDays = Number(process.env.REFRESH_TOKEN_TTL_DAYS || 7);
  const refreshDays = Number.isFinite(configuredRefreshDays)
    ? Math.max(1, Math.min(30, configuredRefreshDays))
    : 7;
  customer.refreshTokenHash = hash(refreshToken);
  customer.refreshTokenExpiresAt = new Date(Date.now() + refreshDays * 86400000);
  await customer.save();
  return { user: safeCustomer(customer), accessToken: jwt.sign({ sub: customer.id, role: customer.role }, process.env.JWT_SECRET, { expiresIn: '15m', jwtid: crypto.randomUUID() }), refreshToken, refreshDays, expiresIn: 900 };
}
async function sendTokenResponse(res, customer, message, status = 200) {
  const tokens = await issueTokens(customer);
  const secure = process.env.NODE_ENV === 'production' ? '; Secure' : '';
  const sameSite = process.env.COOKIE_SAME_SITE || 'Lax';
  res.setHeader('Set-Cookie', `refreshToken=${encodeURIComponent(tokens.refreshToken)}; HttpOnly; SameSite=${sameSite}; Path=/; Max-Age=${tokens.refreshDays * 86400}${secure}`);
  res.setHeader('X-Access-Token', tokens.accessToken);
  const data = { user: tokens.user, accessToken: tokens.accessToken, expiresIn: tokens.expiresIn };
  return res.status(status).json({ success: true, ...(message ? { message } : {}), data });
}
function extractRefreshToken(req) {
  const cookieValue = String(req.headers.cookie || '').match(/(?:^|;\s*)(?:refreshToken|refresh_token)=([^;]+)/)?.[1];
  if (cookieValue) return decodeURIComponent(cookieValue);
  return req.body.refreshToken || req.body.refresh_token || req.headers['x-refresh-token'] || null;
}
router.post('/auth/register/request-code', async (req, res, next) => {
  try {
    const name = String(req.body.name || '').trim();
    const phone = String(req.body.phone || '').trim();
    const email = String(req.body.email || '').trim().toLowerCase();
    if (!name || !phone || !/^\S+@\S+\.\S+$/.test(email)) {
      return res.status(400).json({ success: false, error: 'Nhập họ tên, số điện thoại và email hợp lệ.', code: 'VALIDATION_ERROR' });
    }
    if (await Customer.findOne({ $or: [{ email }, { phone }] })) {
      return res.status(409).json({ success: false, error: 'Email hoặc số điện thoại đã được sử dụng.', code: 'ACCOUNT_EXISTS' });
    }
    const host = process.env.SMTP_HOST;
    const port = Number(process.env.SMTP_PORT || 587);
    const from = process.env.SMTP_FROM || process.env.SMTP_USER;
    if (!host || !from || !process.env.SMTP_USER || !process.env.SMTP_PASS) {
      return res.status(503).json({ success: false, error: 'Dịch vụ gửi email chưa được cấu hình.', code: 'EMAIL_NOT_CONFIGURED' });
    }
    const now = new Date();
    let verification = await SignupEmailVerification.findOne({ email });
    if (verification && now - verification.lastSentAt < 60_000) {
      return success(res, { accepted: true }, 'Nếu email có thể đăng ký, mã xác thực sẽ được gửi đến hộp thư.');
    }
    const code = crypto.randomInt(0, 1_000_000).toString().padStart(6, '0');
    if (!verification) verification = new SignupEmailVerification({ email });
    verification.codeHash = hash(code);
    verification.expiresAt = new Date(now.getTime() + 10 * 60_000);
    verification.attempts = 0;
    verification.lastSentAt = now;
    await verification.save();
    const transporter = nodemailer.createTransport({
      host,
      port,
      secure: process.env.SMTP_SECURE === 'true' || port === 465,
      auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
    });
    try {
      await transporter.sendMail({
        from,
        to: email,
        subject: 'Xác thực email đăng ký - MAXKO F&B',
        text: `Mã xác thực đăng ký của bạn là ${code}. Mã có hiệu lực trong 10 phút. Nếu bạn không yêu cầu, hãy bỏ qua email này.`,
        html: `<div style="font-family:Arial,sans-serif;color:#222"><h2>MAXKO F&amp;B GROUP</h2><p>Mã xác thực email đăng ký:</p><p style="font-size:28px;font-weight:bold;letter-spacing:8px;color:#f95721">${code}</p><p>Mã có hiệu lực trong 10 phút. Nếu bạn không yêu cầu, hãy bỏ qua email này.</p></div>`,
      });
    } catch (mailError) {
      await verification.deleteOne();
      return next(mailError);
    }
    return success(res, { accepted: true }, 'Nếu email có thể đăng ký, mã xác thực sẽ được gửi đến hộp thư.');
  } catch (error) { next(error); }
});

router.post('/auth/register', async (req, res, next) => {
  try {
    const { name, phone, password } = req.body;
    const email = String(req.body.email || '').trim().toLowerCase();
    const code = String(req.body.code || '').trim();
    if (!name || !phone || !/^\S+@\S+\.\S+$/.test(email) || !/^\d{6}$/.test(code) || !password) {
      return res.status(400).json({ success: false, error: 'Vui lòng nhập đầy đủ thông tin và mã xác thực.', code: 'VALIDATION_ERROR' });
    }
    if (String(password).length < 8) return res.status(400).json({ success: false, error: 'Mật khẩu cần ít nhất 8 ký tự.', code: 'VALIDATION_ERROR' });
    const verification = await SignupEmailVerification.findOne({ email });
    const now = new Date();
    if (!verification || !verification.codeHash || !verification.expiresAt || verification.expiresAt <= now || verification.attempts >= 5) {
      return res.status(400).json({ success: false, error: 'Mã xác thực không hợp lệ hoặc đã hết hạn. Hãy yêu cầu mã mới.', code: 'SIGNUP_CODE_INVALID' });
    }
    const actualHash = Buffer.from(hash(code), 'hex');
    const expectedHash = Buffer.from(verification.codeHash, 'hex');
    if (expectedHash.length !== actualHash.length || !crypto.timingSafeEqual(expectedHash, actualHash)) {
      verification.attempts += 1;
      await verification.save();
      return res.status(400).json({ success: false, error: 'Mã xác thực không chính xác.', code: 'SIGNUP_CODE_INVALID' });
    }
    if (await Customer.findOne({ $or: [{ email }, { phone: String(phone).trim() }] })) {
      await verification.deleteOne();
      return res.status(409).json({ success: false, error: 'Email hoặc số điện thoại đã được sử dụng.', code: 'ACCOUNT_EXISTS' });
    }
    const customer = await Customer.create({
      name: String(name).trim(),
      phone: String(phone).trim(),
      email,
      passwordHash: await bcrypt.hash(password, 12),
    });
    await verification.deleteOne();
    return sendTokenResponse(res, customer, 'Đăng ký tài khoản thành công.', 201);
  } catch (error) { next(error); }
});

router.post('/auth/login', async (req, res, next) => {
  try {
    const customer = await Customer.findOne({ email: String(req.body.email || '').trim().toLowerCase() });
    if (!customer || !(await bcrypt.compare(req.body.password || '', customer.passwordHash))) return res.status(401).json({ success: false, error: 'Email hoặc mật khẩu không đúng.', code: 'INVALID_CREDENTIALS' });
    return sendTokenResponse(res, customer, 'Đăng nhập thành công.');
  } catch (error) { next(error); }
});
router.post('/auth/change-password', requireAuth, async (req, res, next) => {
  try {
    const currentPassword = String(req.body.currentPassword || '');
    const newPassword = String(req.body.newPassword || '');
    if (!currentPassword || newPassword.length < 8) {
      return res.status(400).json({ success: false, error: 'Nhập mật khẩu hiện tại và mật khẩu mới có ít nhất 8 ký tự.', code: 'VALIDATION_ERROR' });
    }
    if (!(await bcrypt.compare(currentPassword, req.customer.passwordHash))) {
      return res.status(400).json({ success: false, error: 'Mật khẩu hiện tại không chính xác.', code: 'CURRENT_PASSWORD_INVALID' });
    }
    if (await bcrypt.compare(newPassword, req.customer.passwordHash)) {
      return res.status(400).json({ success: false, error: 'Mật khẩu mới phải khác mật khẩu hiện tại.', code: 'PASSWORD_UNCHANGED' });
    }
    req.customer.passwordHash = await bcrypt.hash(newPassword, 12);
    await req.customer.save();
    return success(res, { passwordChanged: true }, 'Mật khẩu đã được cập nhật.');
  } catch (error) { next(error); }
});

router.post('/auth/forgot-password', async (req, res, next) => {
  try {
    const email = String(req.body.email || '').trim().toLowerCase();
    if (!/^\S+@\S+\.\S+$/.test(email)) {
      return res.status(400).json({ success: false, error: 'Vui lòng nhập địa chỉ email hợp lệ.', code: 'VALIDATION_ERROR' });
    }

    const host = process.env.SMTP_HOST;
    const port = Number(process.env.SMTP_PORT || 587);
    const from = process.env.SMTP_FROM || process.env.SMTP_USER;
    if (!host || !from || !process.env.SMTP_USER || !process.env.SMTP_PASS) {
      return res.status(503).json({ success: false, error: 'Dịch vụ gửi email chưa được cấu hình.', code: 'EMAIL_NOT_CONFIGURED' });
    }

    const customer = await Customer.findOne({ email });
    if (!customer) return success(res, { accepted: true }, 'Nếu email đã đăng ký, mã xác thực sẽ được gửi đến hộp thư.');

    const now = new Date();
    if (customer.passwordResetLastSentAt && now - customer.passwordResetLastSentAt < 60_000) {
      return success(res, { accepted: true }, 'Nếu email đã đăng ký, mã xác thực sẽ được gửi đến hộp thư.');
    }

    const code = crypto.randomInt(0, 1_000_000).toString().padStart(6, '0');
    customer.passwordResetCodeHash = hash(code);
    customer.passwordResetCodeExpiresAt = new Date(now.getTime() + 10 * 60_000);
    customer.passwordResetCodeAttempts = 0;
    customer.passwordResetLastSentAt = now;
    await customer.save();

    const transporter = nodemailer.createTransport({
      host,
      port,
      secure: process.env.SMTP_SECURE === 'true' || port === 465,
      auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
    });
    try {
      await transporter.sendMail({
        from,
        to: customer.email,
        subject: 'Mã xác thực đặt lại mật khẩu - MAXKO F&B',
        text: `Mã xác thực đặt lại mật khẩu của bạn là ${code}. Mã có hiệu lực trong 10 phút. Nếu bạn không yêu cầu, hãy bỏ qua email này.`,
        html: `<div style="font-family:Arial,sans-serif;color:#222"><h2>MAXKO F&amp;B GROUP</h2><p>Mã xác thực đặt lại mật khẩu của bạn:</p><p style="font-size:28px;font-weight:bold;letter-spacing:8px;color:#f95721">${code}</p><p>Mã có hiệu lực trong 10 phút. Nếu bạn không yêu cầu, hãy bỏ qua email này.</p></div>`,
      });
    } catch (mailError) {
      customer.passwordResetCodeHash = null;
      customer.passwordResetCodeExpiresAt = null;
      await customer.save();
      return next(mailError);
    }

    return success(res, { accepted: true }, 'Nếu email đã đăng ký, mã xác thực sẽ được gửi đến hộp thư.');
  } catch (error) { next(error); }
});

router.post('/auth/reset-password', async (req, res, next) => {
  try {
    const email = String(req.body.email || '').trim().toLowerCase();
    const code = String(req.body.resetToken || req.body.code || '').trim();
    const password = String(req.body.newPassword || req.body.password || '');
    if (!code || password.length < 8 || (email && !/^\S+@\S+\.\S+$/.test(email))) {
      return res.status(400).json({ success: false, error: 'Email, mã xác thực hoặc mật khẩu chưa hợp lệ.', code: 'VALIDATION_ERROR' });
    }

    const customer = email
      ? await Customer.findOne({ email })
      : await Customer.findOne({ passwordResetCodeHash: hash(code) });
    const now = new Date();
    if (!customer || !customer.passwordResetCodeHash || !customer.passwordResetCodeExpiresAt ||
        customer.passwordResetCodeExpiresAt <= now || customer.passwordResetCodeAttempts >= 5) {
      return res.status(400).json({ success: false, error: 'Mã không hợp lệ hoặc đã hết hạn. Hãy yêu cầu mã mới.', code: 'RESET_CODE_INVALID' });
    }
    const suppliedHash = hash(code);
    const expectedHash = Buffer.from(customer.passwordResetCodeHash, 'hex');
    const actualHash = Buffer.from(suppliedHash, 'hex');
    if (expectedHash.length !== actualHash.length || !crypto.timingSafeEqual(expectedHash, actualHash)) {
      customer.passwordResetCodeAttempts += 1;
      await customer.save();
      return res.status(400).json({ success: false, error: 'Mã xác thực không chính xác.', code: 'RESET_CODE_INVALID' });
    }

    customer.passwordHash = await bcrypt.hash(password, 12);
    customer.passwordResetCodeHash = null;
    customer.passwordResetCodeExpiresAt = null;
    customer.passwordResetCodeAttempts = 0;
    customer.refreshTokenHash = null;
    customer.refreshTokenExpiresAt = null;
    await customer.save();
    return success(res, { passwordReset: true }, 'Mật khẩu đã được cập nhật.');
  } catch (error) { next(error); }
});
router.post('/auth/refresh-token', async (req, res, next) => {
  try {
    const refreshToken = extractRefreshToken(req);
    const customer = refreshToken ? await Customer.findOne({ refreshTokenHash: hash(refreshToken), refreshTokenExpiresAt: { $gt: new Date() } }) : null;
    if (!customer) return res.status(401).json({ success: false, error: 'Phiên làm việc hết hạn.' });
    return sendTokenResponse(res, customer, 'Làm mới phiên làm việc thành công.');
  } catch (error) { next(error); }
});
router.post('/auth/refresh', async (req, res, next) => {
  try {
    const refreshToken = extractRefreshToken(req);
    const customer = refreshToken ? await Customer.findOne({ refreshTokenHash: hash(refreshToken), refreshTokenExpiresAt: { $gt: new Date() } }) : null;
    if (!customer) return res.status(401).json({ success: false, error: 'Phiên làm việc hết hạn.', code: 'UNAUTHORIZED' });
    return sendTokenResponse(res, customer, 'Làm mới phiên làm việc thành công.');
  } catch (error) { next(error); }
});
router.get('/auth/me', requireAuth, (req, res) => success(res, safeCustomer(req.customer)));
router.put('/auth/me', requireAuth, async (req, res, next) => {
  try {
    const updates = {};
    if (req.body.name !== undefined) {
      const name = String(req.body.name).trim();
      if (!name || name.length > 100) {
        return res.status(400).json({ success: false, error: 'Tên hiển thị không hợp lệ.', code: 'VALIDATION_ERROR' });
      }
      updates.name = name;
    }
    if (req.body.phone !== undefined) {
      const phone = String(req.body.phone).trim();
      if (!/^\+?[0-9 ()-]{8,20}$/.test(phone)) {
        return res.status(400).json({ success: false, error: 'Số điện thoại không hợp lệ.', code: 'VALIDATION_ERROR' });
      }
      const existing = await Customer.findOne({ phone, _id: { $ne: req.customer._id } }).select('_id').lean();
      if (existing) return res.status(409).json({ success: false, error: 'Số điện thoại đã được sử dụng.', code: 'ACCOUNT_EXISTS' });
      updates.phone = phone;
    }
    if (req.body.birthday !== undefined) {
      const birthday = req.body.birthday === null ? null : new Date(req.body.birthday);
      if (birthday && Number.isNaN(birthday.getTime())) {
        return res.status(400).json({ success: false, error: 'Ngày sinh không hợp lệ.', code: 'VALIDATION_ERROR' });
      }
      updates.birthday = birthday;
    }
    if (req.body.gender !== undefined) {
      const gender = String(req.body.gender).toLowerCase();
      if (!['unspecified', 'female', 'male', 'other'].includes(gender)) {
        return res.status(400).json({ success: false, error: 'Giới tính không hợp lệ.', code: 'VALIDATION_ERROR' });
      }
      updates.gender = gender;
    }
    Object.assign(req.customer, updates);
    await req.customer.save();
    return success(res, safeCustomer(req.customer), 'Đã cập nhật hồ sơ.');
  } catch (error) { next(error); }
});
router.post('/auth/logout', requireAuth, async (req, res, next) => {
  try {
    revoke(req.authPayload?.jti, req.authPayload?.exp);
    req.customer.refreshTokenHash = null;
    req.customer.refreshTokenExpiresAt = null;
    await req.customer.save();
    const secure = process.env.NODE_ENV === 'production' ? '; Secure' : '';
    const sameSite = process.env.COOKIE_SAME_SITE || 'Lax';
    res.setHeader('Set-Cookie', [
      `refreshToken=; HttpOnly; SameSite=${sameSite}; Path=/; Max-Age=0${secure}`,
      `refresh_token=; HttpOnly; SameSite=${sameSite}; Path=/; Max-Age=0${secure}`,
    ]);
    success(res, { loggedOut: true }, 'Đã đăng xuất.');
  }
  catch (error) { next(error); }
});

router.get('/bootstrap', async (req, res, next) => {
  try {
    const products = await Product.find({ isAvailable: true }).sort({ createdAt: -1 }).lean();
    const categories = [...new Set(products.map((product) => product.category))].map((name, i) => ({ id: `cat-${i + 1}`, name }));
    const toppings = [...new Map(products.flatMap((product) => product.toppings || []).map((item) => [item.name, { id: item.name, name: item.name, price: item.extraPrice, isAvailable: true }])).values()];
    const vouchers = await Voucher.find({ isActive: true, ownerCustomer: null }).lean();
    const branches = await Branch.find({ isActive: true, isOpen: true }).lean();
    const now = new Date();
    const promotions = await Promotion.find({ isActive: true, $and: [
      { $or: [{ startDate: null }, { startDate: { $lte: now } }] },
      { $or: [{ endDate: null }, { endDate: { $gte: now } }] },
    ] }).sort({ startDate: 1 }).lean();
    const campaigns = promotions.map((item) => ({
      id: String(item._id),
      title: item.title,
      description: item.description,
      voucherCode: item.code || '',
      startDate: item.startDate,
      endDate: item.endDate,
    }));
    success(res, { branches, categories, products, toppings, vouchers, campaigns });
  } catch (error) { next(error); }
});
router.get('/customers/campaigns', async (req, res, next) => {
  try {
    const now = new Date();
    const filter = { isActive: true, $and: [
      { $or: [{ startDate: null }, { startDate: { $lte: now } }] },
      { $or: [{ endDate: null }, { endDate: { $gte: now } }] },
    ] };
    if (req.query.brandId) filter.$and.push({ $or: [{ brandIds: { $size: 0 } }, { brandIds: String(req.query.brandId) }] });
    const promotions = await Promotion.find(filter).sort({ startDate: 1 }).lean();
    success(res, promotions.map((item) => ({
      id: String(item._id),
      title: item.title,
      description: item.description,
      voucherCode: item.code || '',
      startDate: item.startDate,
      endDate: item.endDate,
    })));
  } catch (error) { next(error); }
});
router.get('/customers/vouchers', optionalAuth, async (req, res, next) => {
  try {
    const ownership = req.customer
      ? [{ ownerCustomer: null }, { ownerCustomer: req.customer._id }]
      : [{ ownerCustomer: null }];
    const filter = { isActive: true, usedAt: null, $or: ownership };
    if (req.query.brandId) filter.$and = [{ $or: [{ brandIds: { $size: 0 } }, { brandIds: String(req.query.brandId) }] }];
    success(res, await Voucher.find(filter).sort({ endDate: 1 }).lean());
  } catch (error) { next(error); }
});
router.get('/customers/rewards', async (req, res, next) => {
  try {
    const filter = { isActive: true };
    if (req.query.brandId) filter.$or = [{ brandIds: { $size: 0 } }, { brandIds: String(req.query.brandId) }];
    const rewards = await Reward.find(filter).sort({ pointsCost: 1 }).lean();
    success(res, rewards.map((item) => ({ id: String(item._id), code: item.code, title: item.title, description: item.description, pointsCost: item.pointsCost, discountPercent: item.discountPercent, discountAmount: item.discountAmount, maxDiscount: item.maxDiscount, minOrderTotal: item.minOrderTotal })));
  } catch (error) { next(error); }
});
router.post('/customers/redeem-voucher', requireAuth, async (req, res, next) => {
  try {
    const reward = await Reward.findOne({ $or: [{ _id: req.body.rewardId }, { code: String(req.body.code || '').trim().toUpperCase() }], isActive: true });
    if (!reward) return res.status(404).json({ success: false, error: 'Không tìm thấy phần thưởng.', code: 'REWARD_NOT_FOUND' });
    const now = new Date();
    const updated = await Customer.findOneAndUpdate(
      { _id: req.customer._id, loyaltyPoints: { $gte: reward.pointsCost } },
      { $inc: { loyaltyPoints: -reward.pointsCost }, $push: { pointsHistory: { date: now, description: `Đổi quà: ${reward.title}`, points: -reward.pointsCost } } },
      { new: true },
    );
    if (!updated) return res.status(400).json({ success: false, error: 'Bạn chưa đủ điểm để đổi phần thưởng này.', code: 'INSUFFICIENT_POINTS' });
    const validity = Math.max(1, Number(reward.validityDays || 30));
    let voucher;
    try {
      voucher = await Voucher.create({
        code: `MK${crypto.randomBytes(5).toString('hex').toUpperCase()}`,
        title: reward.title,
        discountPercent: reward.discountPercent,
        discountAmount: reward.discountAmount,
        maxDiscount: reward.maxDiscount,
        minOrderTotal: reward.minOrderTotal,
        ownerCustomer: updated._id,
        source: 'POINT_REDEMPTION',
        brandIds: reward.brandIds,
        startDate: now,
        endDate: new Date(now.getTime() + validity * 86400000),
        isActive: true,
      });
    } catch (error) {
      await Customer.updateOne({ _id: updated._id }, { $inc: { loyaltyPoints: reward.pointsCost }, $pull: { pointsHistory: { date: now, description: `Đổi quà: ${reward.title}` } } });
      throw error;
    }
    success(res, { voucher: { id: String(voucher._id), code: voucher.code, title: voucher.title, endDate: voucher.endDate }, loyaltyPoints: updated.loyaltyPoints }, 'Đổi điểm thành công.');
  } catch (error) { next(error); }
});
router.get('/products/categories', async (req, res, next) => {
  try {
    const filter = { isAvailable: true };
    if (req.query.brandId) filter.brandId = req.query.brandId === 'brand-legia' ? { $in: ['brand-legia', null] } : String(req.query.brandId);
    const values = (await Product.distinct('category', filter)).sort();
    success(res, values.map((name, i) => ({ id: `cat-${i + 1}`, name })));
  }
  catch (error) { next(error); }
});
router.get('/products/categories/all', async (req, res, next) => {
  try {
    const filter = { isAvailable: true };
    if (req.query.brandId) filter.brandId = req.query.brandId === 'brand-legia' ? { $in: ['brand-legia', null] } : String(req.query.brandId);
    const values = (await Product.distinct('category', filter)).sort();
    success(res, values.map((name, i) => ({ id: `cat-${i + 1}`, name })));
  } catch (error) { next(error); }
});
router.get('/modifier-groups', async (req, res, next) => {
  try {
    const filter = { isActive: true };
    if (req.query.brandId) filter.brandId = String(req.query.brandId);
    const groups = await ModifierGroup.find(filter).sort({ name: 1 }).lean();
    success(res, groups.map((group) => ({ ...group, id: group.id || String(group._id) })));
  } catch (error) { next(error); }
});
router.get('/modifier-groups/:id', async (req, res, next) => {
  try {
    const group = await ModifierGroup.findOne({ id: req.params.id, isActive: true }).lean();
    if (!group) return res.status(404).json({ success: false, error: 'Không tìm thấy nhóm tùy chọn.', code: 'MODIFIER_GROUP_NOT_FOUND' });
    success(res, { ...group, id: group.id || String(group._id) });
  } catch (error) { next(error); }
});
router.get('/products/toppings', async (req, res, next) => {
  try {
    const products = await Product.find({ isAvailable: true }, 'toppings').lean();
    const items = new Map();
    products.flatMap((p) => p.toppings || []).forEach((item) => items.set(item.name, { id: item.name, name: item.name, price: item.extraPrice, isAvailable: true }));
    success(res, [...items.values()]);
  } catch (error) { next(error); }
});
router.post('/customers/vouchers/validate', optionalAuth, async (req, res, next) => {
  try {
    const code = String(req.body.code || '').trim().toUpperCase();
    const orderTotal = Number(req.body.orderTotal || 0);
    const voucher = await Voucher.findOne({ code, isActive: true });
    const now = new Date();
    if (voucher && (!voucher.ownerCustomer || String(voucher.ownerCustomer) === String(req.customer?._id || '')) && !voucher.usedAt && !voucher.pointsCost && orderTotal >= voucher.minOrderTotal && (!voucher.startDate || voucher.startDate <= now) && (!voucher.endDate || voucher.endDate >= now)) {
      const discountAmount = Math.round(Math.min(voucher.discountAmount || orderTotal * voucher.discountPercent / 100, voucher.maxDiscount || Number.MAX_SAFE_INTEGER, orderTotal));
      return success(res, { isValid: true, discountAmount, finalTotal: Math.max(0, orderTotal - discountAmount), voucher: { code, discountPercent: voucher.discountPercent, maxDiscount: voucher.maxDiscount } });
    }
    if (!voucher) {
      const promotion = await Promotion.findOne({ code, isActive: true }).lean();
      if (promotion && (!promotion.startDate || promotion.startDate <= now) && (!promotion.endDate || promotion.endDate >= now) && orderTotal >= Number(promotion.minOrderTotal || 0)) {
        const raw = promotion.type === 'PERCENT' ? orderTotal * Number(promotion.value || 0) / 100 : Number(promotion.value || 0);
        const discountAmount = Math.round(Math.min(raw, promotion.maxDiscount || Number.MAX_SAFE_INTEGER, orderTotal));
        return success(res, { isValid: true, discountAmount, finalTotal: Math.max(0, orderTotal - discountAmount), voucher: { code, title: promotion.title } });
      }
    }
    return res.status(400).json({ success: false, error: 'Voucher hoặc mã khuyến mãi không hợp lệ hay không đủ điều kiện.', code: 'VOUCHER_INVALID' });
  } catch (error) { next(error); }
});

router.post('/orders', optionalAuth, async (req, res, next) => {
  try {
    const { items, customerName, customerPhone } = req.body;
    if (!Array.isArray(items) || !items.length || !customerName || !customerPhone) return res.status(400).json({ success: false, error: 'Thông tin đơn hàng chưa đầy đủ.' });
    const ids = [...new Set(items.map((item) => item.productId).filter(mongoose.isValidObjectId))];
    const products = await Product.find({ _id: { $in: ids }, isAvailable: true }).lean();
    const { normalizedItems, subtotal } = normalizeOrderItems(items, products);
    const voucher = req.body.voucherCode ? await Voucher.findOne({ code: String(req.body.voucherCode).toUpperCase(), isActive: true }) : null;
    if (req.body.voucherCode && (!voucher || subtotal < voucher.minOrderTotal || (voucher.startDate && voucher.startDate > new Date()) || (voucher.endDate && voucher.endDate < new Date()))) return res.status(400).json({ success: false, error: 'Voucher không hợp lệ hoặc không đủ điều kiện áp dụng.', code: 'VOUCHER_INVALID' });
    const discount = voucher ? Math.min(voucher.discountAmount || subtotal * voucher.discountPercent / 100, voucher.maxDiscount || Number.MAX_SAFE_INTEGER, subtotal) : 0;
    const shippingFee = req.body.orderType === 'DELIVERY'
      ? Math.max(0, Number(process.env.DELIVERY_FEE || 0))
      : 0;
    const paymentMethod = String(req.body.paymentMethod || 'CASH').toUpperCase();
    if (paymentMethod !== 'CASH') return res.status(400).json({ success: false, error: 'Thanh toán trực tuyến chưa được cấu hình. Vui lòng chọn tiền mặt.', code: 'PAYMENT_METHOD_UNAVAILABLE' });
    const order = await Order.create({
      customer: req.user?.id || null, branchId: req.body.branchId || '', orderType: req.body.orderType || 'TAKEAWAY', source: 'APP',
      customerName, customerPhone, deliveryAddress: req.body.deliveryAddress || '', items: normalizedItems,
      note: req.body.note || '',
      subtotal, discount, shippingFee, finalTotal: subtotal - discount + shippingFee,
      paymentMethod, paymentStatus: 'UNPAID', status: 'PENDING', statusTimeline: [{ status: 'PENDING', time: new Date() }],
      voucherCode: voucher?.code || '', needCorporateInvoice: Boolean(req.body.needCorporateInvoice), corporateInvoiceInfo: req.body.corporateInvoiceInfo,
    });
    res.status(201).json({ success: true, message: 'Đơn hàng đã được tạo thành công.', data: { id: order.id, orderNumber: order.orderNumber, status: order.status, finalTotal: order.finalTotal, paymentMethod: order.paymentMethod, paymentStatus: order.paymentStatus, createdAt: order.createdAt } });
  } catch (error) {
    if (error.statusCode === 400) return res.status(400).json({ success: false, error: error.message, code: error.code });
    next(error);
  }
});
router.get('/orders/my-orders', requireAuth, async (req, res, next) => {
  try { success(res, await Order.find({ customer: req.customer.id }).sort({ createdAt: -1 }).lean()); } catch (error) { next(error); }
});
router.patch('/orders/:id/cancel', requireAuth, async (req, res, next) => {
  try {
    const query = mongoose.isValidObjectId(req.params.id) ? { _id: req.params.id } : { orderNumber: req.params.id };
    const order = await Order.findOne({ ...query, customer: req.customer._id });
    if (!order) return res.status(404).json({ success: false, error: 'Không tìm thấy đơn hàng của tài khoản này.', code: 'ORDER_NOT_FOUND' });
    if (!['PENDING', 'SUBMITTED', 'CONFIRMED'].includes(order.status)) return res.status(409).json({ success: false, error: 'Đơn hàng đã được chuẩn bị và không thể hủy.', code: 'ORDER_CANNOT_CANCEL' });
    order.status = 'CANCELLED';
    order.statusTimeline.push({ status: 'CANCELLED', time: new Date() });
    await order.save();
    success(res, { id: order.id, orderNumber: order.orderNumber, status: order.status }, 'Đã hủy đơn hàng.');
  } catch (error) { next(error); }
});
const devOnly = (req, res, next) => {
  if (process.env.NODE_ENV === 'production') return res.status(404).json({ success: false, error: 'Không tìm thấy API endpoint.', code: 'NOT_FOUND' });
  next();
};

router.patch('/dev/orders/:id/status', devOnly, requireAuth, async (req, res, next) => {
  try {
    const allowedStatuses = ['CONFIRMED', 'PREPARING', 'READY', 'OUT_FOR_DELIVERY', 'COMPLETED'];
    const status = String(req.body.status || '').toUpperCase();
    if (!allowedStatuses.includes(status)) return res.status(400).json({ success: false, error: 'Trạng thái không hợp lệ. Cho phép: ' + allowedStatuses.join(', ') + '.', code: 'INVALID_ORDER_STATUS' });
    const query = mongoose.isValidObjectId(req.params.id) ? { _id: req.params.id } : { orderNumber: req.params.id };
    const order = await Order.findOne({ ...query, customer: req.customer._id });
    if (!order) return res.status(404).json({ success: false, error: 'Không tìm thấy đơn hàng của tài khoản này.', code: 'ORDER_NOT_FOUND' });
    if (order.status === 'COMPLETED') return res.status(409).json({ success: false, error: 'Đơn đã hoàn tất và không thể đổi trạng thái.', code: 'ORDER_ALREADY_COMPLETED' });
    order.status = status;
    order.statusTimeline.push({ status, time: new Date() });
    await order.save();
    success(res, { id: order.id, orderNumber: order.orderNumber, status: order.status, statusTimeline: order.statusTimeline, createdAt: order.createdAt }, 'Đã cập nhật trạng thái đơn hàng.');
  } catch (error) { next(error); }
});

router.get(['/notifications', '/notifications/inbox'], requireAuth, async (req, res, next) => {
  try {
    const notifications = await Notification.find({ customer: req.customer._id }).sort({ createdAt: -1 }).limit(100).lean();
    success(res, notifications.map((item) => ({ id: String(item._id), title: item.title, message: item.message, type: item.type, orderId: item.orderId || '', isRead: item.isRead, timeLabel: item.createdAt ? new Date(item.createdAt).toLocaleString('vi-VN') : '', actionLabel: item.type === 'order' ? 'Xem đơn hàng' : 'Xem thông báo', createdAt: item.createdAt })));
  } catch (error) { next(error); }
});
router.patch(['/notifications/:id/read', '/notifications/inbox/:id/read'], requireAuth, async (req, res, next) => {
  try {
    const notification = await Notification.findOneAndUpdate({ _id: req.params.id, customer: req.customer._id }, { isRead: true }, { new: true });
    if (!notification) return res.status(404).json({ success: false, error: 'Không tìm thấy thông báo.', code: 'NOTIFICATION_NOT_FOUND' });
    success(res, { id: String(notification._id), isRead: notification.isRead });
  } catch (error) { next(error); }
});
router.patch(['/notifications/read-all', '/notifications/inbox/mark-all-read'], requireAuth, async (req, res, next) => {
  try {
    const result = await Notification.updateMany({ customer: req.customer._id, isRead: false }, { isRead: true });
    success(res, { modifiedCount: result.modifiedCount }, 'Đã đánh dấu tất cả thông báo là đã đọc.');
  } catch (error) { next(error); }
});
router.get('/customers/me/addresses', requireAuth, (req, res) => success(res, req.customer.savedAddresses || []));
router.put('/customers/me/addresses', requireAuth, async (req, res, next) => {
  try {
    const addresses = Array.isArray(req.body.addresses) ? req.body.addresses : [];
    if (addresses.length > 10 || addresses.some((item) => !String(item.address || '').trim())) return res.status(400).json({ success: false, error: 'Địa chỉ không hợp lệ (tối đa 10 địa chỉ).', code: 'VALIDATION_ERROR' });
    req.customer.savedAddresses = addresses.map((item, index) => ({ label: String(item.label || 'Nhà').trim(), address: String(item.address).trim(), isDefault: index === 0 }));
    await req.customer.save();
    success(res, req.customer.savedAddresses, 'Đã lưu địa chỉ.');
  } catch (error) { next(error); }
});

// Profile and notification settings used by the account experience.
router.get('/customers/me/profile', requireAuth, (req, res) => success(res, safeCustomer(req.customer)));
router.get('/customers/me/membership', requireAuth, async (req, res, next) => {
  try {
    const history = (req.customer.pointsHistory || []).slice().sort((a, b) => new Date(b.date) - new Date(a.date)).slice(0, 100);
    const vouchers = await Voucher.find({ ownerCustomer: req.customer._id, isActive: true, usedAt: null }).sort({ endDate: 1 }).lean();
    success(res, {
      membershipTier: req.customer.membershipTier,
      loyaltyPoints: req.customer.loyaltyPoints,
      pointsHistory: history,
      vouchers: vouchers.map((voucher) => ({ id: String(voucher._id), code: voucher.code, title: voucher.title, discountPercent: voucher.discountPercent, discountAmount: voucher.discountAmount, maxDiscount: voucher.maxDiscount, minOrderTotal: voucher.minOrderTotal, endDate: voucher.endDate })),
    });
  } catch (error) { next(error); }
});
router.patch('/customers/me/profile', requireAuth, async (req, res, next) => {
  try {
    const updates = {};
    if (Object.prototype.hasOwnProperty.call(req.body, 'name')) {
      const name = String(req.body.name || '').trim();
      if (!name || name.length > 100) return res.status(400).json({ success: false, error: 'Họ tên phải có từ 1 đến 100 ký tự.', code: 'VALIDATION_ERROR' });
      updates.name = name;
    }
    if (Object.prototype.hasOwnProperty.call(req.body, 'phone')) {
      const phone = String(req.body.phone || '').trim();
      if (!/^\+?[0-9 .()-]{8,20}$/.test(phone)) return res.status(400).json({ success: false, error: 'Số điện thoại chưa hợp lệ.', code: 'VALIDATION_ERROR' });
      const existing = await Customer.findOne({ phone, _id: { $ne: req.customer._id } }).select('_id').lean();
      if (existing) return res.status(409).json({ success: false, error: 'Số điện thoại đã được sử dụng.', code: 'PHONE_ALREADY_USED' });
      updates.phone = phone;
    }
    if (Object.prototype.hasOwnProperty.call(req.body, 'birthday')) {
      if (req.body.birthday === null || req.body.birthday === '') updates.birthday = null;
      else {
        const birthday = new Date(req.body.birthday);
        if (Number.isNaN(birthday.getTime()) || birthday > new Date()) return res.status(400).json({ success: false, error: 'Ngày sinh chưa hợp lệ.', code: 'VALIDATION_ERROR' });
        updates.birthday = birthday;
      }
    }
    if (Object.prototype.hasOwnProperty.call(req.body, 'gender')) {
      const gender = String(req.body.gender || 'unspecified').toLowerCase();
      if (!['female', 'male', 'other', 'unspecified'].includes(gender)) return res.status(400).json({ success: false, error: 'Giá trị giới tính chưa hợp lệ.', code: 'VALIDATION_ERROR' });
      updates.gender = gender;
    }
    Object.assign(req.customer, updates);
    await req.customer.save();
    success(res, safeCustomer(req.customer), 'Đã cập nhật hồ sơ.');
  } catch (error) { next(error); }
});

router.get('/customers/me/notification-preferences', requireAuth, (req, res) => success(res, {
  push: req.customer.notificationPreferences?.push ?? true,
  email: req.customer.notificationPreferences?.email ?? true,
  sms: req.customer.notificationPreferences?.sms ?? false,
}));
router.put('/customers/me/notification-preferences', requireAuth, async (req, res, next) => {
  try {
    const current = req.customer.notificationPreferences || {};
    const preferences = { push: current.push ?? true, email: current.email ?? true, sms: current.sms ?? false };
    for (const key of Object.keys(preferences)) {
      if (Object.prototype.hasOwnProperty.call(req.body, key)) {
        if (typeof req.body[key] !== 'boolean') return res.status(400).json({ success: false, error: `Giá trị ${key} phải là true hoặc false.`, code: 'VALIDATION_ERROR' });
        preferences[key] = req.body[key];
      }
    }
    req.customer.notificationPreferences = preferences;
    await req.customer.save();
    success(res, preferences, 'Đã lưu tùy chọn thông báo.');
  } catch (error) { next(error); }
});

router.post('/dev/notifications', devOnly, requireAuth, async (req, res, next) => {
  try {
    const title = String(req.body.title || '').trim();
    const message = String(req.body.message || '').trim();
    const type = String(req.body.type || 'promo').toLowerCase();
    if (!title || !message) return res.status(400).json({ success: false, error: 'Cần nhập title và message.', code: 'VALIDATION_ERROR' });
    if (!['order', 'promo', 'system'].includes(type)) return res.status(400).json({ success: false, error: 'type phải là order, promo hoặc system.', code: 'VALIDATION_ERROR' });
    const notification = await Notification.create({ customer: req.customer._id, title, message, type, orderId: String(req.body.orderId || ''), isRead: false });
    res.status(201).json({ success: true, message: 'Đã tạo thông báo thử nghiệm.', data: { id: String(notification._id), title, message, type, orderId: notification.orderId, isRead: false, createdAt: notification.createdAt } });
  } catch (error) { next(error); }
});

router.get('/orders/:id', requireAuth, async (req, res, next) => {
  try {
    const query = mongoose.isValidObjectId(req.params.id) ? { _id: req.params.id } : { orderNumber: req.params.id };
    const order = await Order.findOne({ ...query, customer: req.customer._id }).lean();
    if (!order) return res.status(404).json({ success: false, error: 'Không tìm thấy đơn hàng.' });
    success(res, { ...order, id: String(order._id), deliveryProgress: null, invoiceDetails: null });
  } catch (error) { next(error); }
});
router.get('/customers/:id/profile-360', requireAuth, async (req, res, next) => {
  try {
    if (req.params.id !== req.customer.id && req.params.id !== String(req.customer._id)) {
      return res.status(403).json({ success: false, error: 'Không có quyền xem hồ sơ khách hàng này.', code: 'FORBIDDEN' });
    }
    const [orders, vouchers] = await Promise.all([
      Order.find({ customer: req.customer._id }).sort({ createdAt: -1 }).limit(5).select('orderNumber status finalTotal createdAt branchName').lean(),
      Voucher.find({ ownerCustomer: req.customer._id, isActive: true, usedAt: null }).sort({ endDate: 1 }).lean(),
    ]);
    const orderCount = await Order.countDocuments({ customer: req.customer._id });
    success(res, {
      ...safeCustomer(req.customer),
      pointsHistory: (req.customer.pointsHistory || []).slice().sort((a, b) => new Date(b.date) - new Date(a.date)).slice(0, 50),
      orderCount,
      recentOrders: orders,
      vouchers: vouchers.map((item) => ({ id: String(item._id), code: item.code, title: item.title, endDate: item.endDate })),
    });
  } catch (error) { next(error); }
});
router.get('/customers/:id', requireAuth, async (req, res) => {
  if (req.params.id !== req.customer.id) return res.status(403).json({ success: false, error: 'Không có quyền xem tài khoản này.' });
  success(res, { ...safeCustomer(req.customer), pointsHistory: req.customer.pointsHistory });
});
router.post('/customers/register-device', requireAuth, async (req, res, next) => {
  try {
    const { fcmToken, platform, deviceModel } = req.body;
    if (!fcmToken) return res.status(400).json({ success: false, error: 'Thiếu FCM token.' });
    req.customer.devices = req.customer.devices.filter((device) => device.fcmToken !== fcmToken);
    req.customer.devices.push({ fcmToken, platform, deviceModel });
    await req.customer.save();
    success(res, { registered: true });
  } catch (error) { next(error); }
});

router.get('/payments/mqr/banks', (req, res) => success(res, [
  { bankCode: 'VCB', bankName: 'Vietcombank', schemeUrl: 'vcb://' }, { bankCode: 'MB', bankName: 'MBBank', schemeUrl: 'mbmobile://' },
  { bankCode: 'TCB', bankName: 'Techcombank', schemeUrl: 'techcombank://' }, { bankCode: 'VPB', bankName: 'VPBank', schemeUrl: 'vpbank://' },
  { bankCode: 'MOMO', bankName: 'MoMo', schemeUrl: 'momo://' }, { bankCode: 'ZALOPAY', bankName: 'ZaloPay', schemeUrl: 'zalopay://' },
]));
router.post(['/payments/mqr/generate', '/payment/qr/generate'], async (req, res, next) => {
  try {
    const orderId = String(req.body.orderId || '');
    const order = mongoose.isValidObjectId(orderId)
      ? await Order.findById(orderId)
      : await Order.findOne({ orderNumber: orderId });
    if (!order) return res.status(404).json({ success: false, error: 'Không tìm thấy đơn hàng.' });
    return res.status(503).json({ success: false, error: 'VietQR generation requires bank account settings and an approved QR provider connection.', code: 'PAYMENT_NOT_CONFIGURED' });
  } catch (error) { next(error); }
});
router.post('/payment/batch/generate-qr', (req, res) => res.status(503).json({
  success: false,
  error: 'VietQR thanh toán đơn gom chưa được cấu hình.',
  message: 'VietQR thanh toán đơn gom chưa được cấu hình.',
  code: 'PAYMENT_NOT_CONFIGURED',
}));
router.get('/payments/mqr/status/:orderId', async (req, res, next) => {
  try {
    const order = await Order.findById(req.params.orderId);
    if (!order) return res.status(404).json({ success: false, error: 'Không tìm thấy đơn hàng.' });
    success(res, { orderId: order.id, paymentStatus: order.paymentStatus, paidAt: order.paymentStatus === 'PAID' ? order.updatedAt : null, transactionId: order.paymentTransactionId || null });
  } catch (error) { next(error); }
});

router.get('/invoices/tax-lookup/:taxCode', (req, res) => res.status(503).json({ ok: false, error: 'Tra cứu MST cần cấu hình nhà cung cấp dữ liệu thuế.' }));
router.get('/invoices/:orderId/xml', async (req, res, next) => {
  try { const order = await Order.findById(req.params.orderId); if (!order) return res.status(404).json({ ok: false, error: 'Không tìm thấy hóa đơn.' }); return res.status(503).json({ ok: false, error: 'Hóa đơn điện tử chưa được phát hành.' }); }
  catch (error) { next(error); }
});
router.get('/invoices/:orderId/print', async (req, res, next) => {
  try { const order = await Order.findById(req.params.orderId); if (!order) return res.status(404).json({ success: false, error: 'Không tìm thấy hóa đơn.' }); return res.status(503).json({ success: false, error: 'Hóa đơn điện tử chưa được phát hành.' }); }
  catch (error) { next(error); }
});

module.exports = router;
