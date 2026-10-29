const mongoose = require('mongoose');

const luckyWheelSpinSchema = new mongoose.Schema({
  customer: { type: mongoose.Schema.Types.ObjectId, ref: 'Customer', required: true, index: true },
  prizeId: { type: String, required: true },
  prizeLabel: { type: String, required: true },
  rewardType: { type: String, required: true },
  pointsAwarded: { type: Number, default: 0 },
  voucherCode: { type: String, default: '' },
  dayKey: { type: String, required: true, index: true },
}, { timestamps: true });

luckyWheelSpinSchema.index({ customer: 1, createdAt: -1 });

module.exports = mongoose.model('LuckyWheelSpin', luckyWheelSpinSchema);
