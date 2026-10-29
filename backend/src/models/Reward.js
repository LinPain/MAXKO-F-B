const mongoose = require('mongoose');

const rewardSchema = new mongoose.Schema({
  code: { type: String, required: true, unique: true, uppercase: true, trim: true },
  title: { type: String, required: true, trim: true },
  description: { type: String, default: '' },
  pointsCost: { type: Number, required: true, min: 1 },
  discountPercent: { type: Number, default: 0, min: 0, max: 100 },
  discountAmount: { type: Number, default: 0, min: 0 },
  maxDiscount: { type: Number, default: 0, min: 0 },
  minOrderTotal: { type: Number, default: 0, min: 0 },
  validityDays: { type: Number, default: 30, min: 1 },
  brandIds: { type: [String], default: [] },
  isActive: { type: Boolean, default: true },
}, { timestamps: true });

module.exports = mongoose.model('Reward', rewardSchema);
