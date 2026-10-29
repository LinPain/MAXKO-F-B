const mongoose = require('mongoose');

const checkoutIdempotencySchema = new mongoose.Schema({
  scope: { type: String, required: true },
  key: { type: String, required: true },
  requestHash: { type: String, required: true },
  state: { type: String, enum: ['PROCESSING', 'COMPLETED'], default: 'PROCESSING' },
  response: { type: mongoose.Schema.Types.Mixed, default: null },
  expiresAt: { type: Date, required: true, index: { expires: 0 } },
}, { timestamps: true });

checkoutIdempotencySchema.index({ scope: 1, key: 1 }, { unique: true });

module.exports = mongoose.model('CheckoutIdempotency', checkoutIdempotencySchema);
