const mongoose = require('mongoose');

const prizeSchema = new mongoose.Schema({
  id: { type: String, required: true },
  label: { type: String, required: true, trim: true },
  probability: { type: Number, required: true, min: 0 },
  rewardType: { type: String, enum: ['NONE', 'POINTS', 'VOUCHER'], default: 'NONE' },
  points: { type: Number, default: 0, min: 0 },
  discountPercent: { type: Number, default: 0, min: 0, max: 100 },
  discountAmount: { type: Number, default: 0, min: 0 },
  maxDiscount: { type: Number, default: 0, min: 0 },
  minOrderTotal: { type: Number, default: 0, min: 0 },
  voucherValidityDays: { type: Number, default: 30, min: 1 },
}, { _id: false });

const configSchema = new mongoose.Schema({
  key: { type: String, default: 'default', unique: true },
  isActive: { type: Boolean, default: true },
  title: { type: String, default: 'Vòng quay may mắn MAXKO' },
  prizes: { type: [prizeSchema], default: [] },
  spinsPerDayByTier: {
    type: Map,
    of: Number,
    default: {},
  },
}, { timestamps: true });

module.exports = mongoose.model('LuckyWheelConfig', configSchema);
