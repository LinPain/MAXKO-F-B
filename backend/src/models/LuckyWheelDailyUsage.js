const mongoose = require('mongoose');

const dailyUsageSchema = new mongoose.Schema({
  customer: { type: mongoose.Schema.Types.ObjectId, ref: 'Customer', required: true },
  dayKey: { type: String, required: true },
  spins: { type: Number, default: 0, min: 0 },
}, { timestamps: true });

dailyUsageSchema.index({ customer: 1, dayKey: 1 }, { unique: true });

module.exports = mongoose.model('LuckyWheelDailyUsage', dailyUsageSchema);
