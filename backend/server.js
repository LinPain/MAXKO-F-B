require('dotenv').config();

const express = require('express');
const cors = require('cors');
const crypto = require('crypto');
const mongoose = require('mongoose');

const connectDatabase = require('./src/config/database');
const productRoutes = require('./src/routes/productRoutes');
const mobileRoutes = require('./src/routes/mobileRoutes');
const orderRoutes = require('./src/routes/orderRoutes');
const branchRoutes = require('./src/routes/branchRoutes');
const marketingRoutes = require('./src/routes/marketingRoutes');
const brandRoutes = require('./src/routes/brandRoutes');
const { createTokenBucket } = require('./src/middleware/rateLimit');
const CheckoutIdempotency = require('./src/models/CheckoutIdempotency');

const app = express();

const PORT = Number(process.env.PORT || 5000);
const allowedOrigins = (process.env.CORS_ORIGINS || '')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);
const globalRateLimit = createTokenBucket({ capacity: 120, refillPerSecond: 25 });
const authRateLimit = createTokenBucket({ capacity: 10, refillPerSecond: 0.5 });
const orderRateLimit = createTokenBucket({ capacity: 30, refillPerSecond: 3 });

app.disable('x-powered-by');
if (process.env.TRUST_PROXY === 'true') app.set('trust proxy', 1);
app.use(cors({
  credentials: true,
  methods: ['GET', 'HEAD', 'POST', 'PATCH', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Accept', 'Content-Type', 'Authorization', 'X-Client-Platform', 'Idempotency-Key', 'X-Refresh-Token', 'X-Request-Id'],
  exposedHeaders: ['X-Access-Token', 'X-Request-Id', 'Retry-After', 'X-RateLimit-Limit', 'X-RateLimit-Remaining'],
  origin(origin, callback) {
    if (!origin || process.env.NODE_ENV !== 'production' || allowedOrigins.includes(origin)) return callback(null, true);
    return callback(null, false);
  },
}));
app.use('/api', (req, res, next) => {
  req.traceId = crypto.randomUUID();
  res.setHeader('X-Request-Id', req.traceId);
  next();
});
app.use(express.json({ limit: '1mb' }));
app.use('/api', globalRateLimit);
app.use('/api/auth', authRateLimit);
app.use('/api/orders', orderRateLimit);

app.use('/api/orders', orderRoutes);
app.use('/api', marketingRoutes);
app.use('/api', branchRoutes);
app.use('/api', brandRoutes);
app.use('/api', mobileRoutes);
app.use('/api/products', productRoutes);

app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'MAXKO F&B customer API is running',
  });
});

app.get('/api/health', (req, res) => {
  const ready = mongoose.connection.readyState === 1;
  res.status(ready ? 200 : 503).json({
    success: ready,
    data: { status: ready ? 'ok' : 'degraded', database: ready ? 'connected' : 'disconnected' },
    traceId: req.traceId,
  });
});

app.use('/api', (req, res) => {
  res.status(404).json({ success: false, error: 'Không tìm thấy API endpoint.', code: 'NOT_FOUND' });
});

app.use((error, req, res, next) => {
  if (res.headersSent) return next(error);
  if (process.env.NODE_ENV !== 'production') console.error(error);
  const status = error.statusCode || (error.code === 11000 ? 409 : error.name === 'ValidationError' || error.name === 'CastError' ? 400 : 500);
  const code = error.code === 11000 ? 'DUPLICATE_VALUE' : error.code || (status >= 500 ? 'INTERNAL_ERROR' : 'BAD_REQUEST');
  const message = status >= 500
    ? 'Lỗi máy chủ.'
    : error.code === 11000
      ? 'Thông tin đã được sử dụng.'
      : error.message || 'Yêu cầu không hợp lệ.';
  res.status(status).json({ success: false, error: message, message, code, traceId: req.traceId, ...(error.data ? { data: error.data } : {}) });
});

async function startServer() {
  if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32) throw new Error('JWT_SECRET must contain at least 32 characters.');
  await connectDatabase();
  await CheckoutIdempotency.init();
  app.listen(PORT, () => process.stdout.write(`MAXKO API listening on port ${PORT}.\n`));
}

startServer().catch((error) => {
  process.stderr.write(`Backend startup failed: ${error.message}\n`);
  process.exitCode = 1;
});
