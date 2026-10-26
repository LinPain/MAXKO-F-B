const mongoose = require('mongoose');

const customerSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  phone: { type: String, required: true, unique: true, trim: true },
  birthday: { type: Date, default: null },
  gender: { type: String, enum: ['female', 'male', 'other', 'unspecified'], default: 'unspecified' },
  notificationPreferences: {
    push: { type: Boolean, default: true },
    email: { type: Boolean, default: true },
    sms: { type: Boolean, default: false },
  },
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  passwordHash: { type: String, required: true },
  role: { type: String, default: 'CUSTOMER', enum: ['CUSTOMER'] },
  membershipTier: { type: String, default: 'BRONZE' },
  loyaltyPoints: { type: Number, default: 0 },
  refreshTokenHash: { type: String, default: null },
  passwordResetCodeHash: { type: String, default: null },
  passwordResetCodeExpiresAt: { type: Date, default: null },
  passwordResetCodeAttempts: { type: Number, default: 0 },
  passwordResetLastSentAt: { type: Date, default: null },
  devices: [{ fcmToken: String, platform: String, deviceModel: String }],
  savedAddresses: [{ label: { type: String, default: 'Nhà' }, address: { type: String, required: true, trim: true }, isDefault: { type: Boolean, default: false } }],
  pointsHistory: [{ date: Date, description: String, points: Number }],
}, { timestamps: true });

module.exports = mongoose.model('Customer', customerSchema);
