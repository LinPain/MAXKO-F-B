const jwt = require('jsonwebtoken');
const Customer = require('../models/Customer');
const { isRevoked } = require('../services/accessTokenRevocation');

module.exports = async function requireAuth(req, res, next) {
  try {
    const token = req.headers.authorization?.replace(/^Bearer\s+/i, '');
    if (!token) return res.status(401).json({ success: false, error: 'Cần đăng nhập để tiếp tục.', code: 'UNAUTHORIZED' });
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    if (isRevoked(payload.jti)) return res.status(401).json({ success: false, error: 'Phiên làm việc đã kết thúc. Đăng nhập lại để tiếp tục.', message: 'Phiên làm việc đã kết thúc. Đăng nhập lại để tiếp tục.', code: 'SESSION_REVOKED' });
    const customer = await Customer.findById(payload.sub);
    if (!customer) return res.status(401).json({ success: false, error: 'Tài khoản không còn tồn tại.', code: 'UNAUTHORIZED' });
    req.customer = customer;
    req.user = { id: customer.id, role: customer.role };
    req.authToken = token;
    req.authPayload = payload;
    next();
  } catch (_) {
    res.status(401).json({ success: false, error: 'Phiên làm việc hết hạn.', code: 'UNAUTHORIZED' });
  }
};
