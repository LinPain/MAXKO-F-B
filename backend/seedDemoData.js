require('dotenv').config();
const mongoose = require('mongoose');
const Branch = require('./src/models/Branch');
const LuckyWheelConfig = require('./src/models/LuckyWheelConfig');
const Reward = require('./src/models/Reward');

async function seedDemoData() {
  if (process.env.NODE_ENV === 'production') {
    throw new Error('Demo records must not be seeded into production.');
  }
  if (!process.env.MONGODB_URI) throw new Error('Set MONGODB_URI before seeding demo data.');
  await mongoose.connect(process.env.MONGODB_URI);

  await Branch.updateOne({ id: 'b-cau-giay' }, { $set: {
    code: 'HN-CG-01',
    name: 'MAXKO F&B - Cầu Giấy (Demo)',
    address: 'Cầu Giấy, Hà Nội',
    phone: '',
    latitude: 21.036237,
    longitude: 105.790583,
    allowedGpsRadiusMeters: 150,
    hubType: 'STANDALONE',
    isOpen: true,
    isActive: true,
    openTime: '08:00',
    closeTime: '22:30',
    brandIds: ['brand-legia'],
  } }, { upsert: true });

  await LuckyWheelConfig.updateOne({ key: 'default' }, { $set: {
    isActive: true,
    title: 'Vòng quay may mắn MAXKO',
    spinsPerDayByTier: { BRONZE: 1, SILVER: 2, GOLD: 3, PLATINUM: 5 },
    prizes: [
      { id: 'off-10', label: '10% OFF', probability: 15, rewardType: 'VOUCHER', discountPercent: 10, maxDiscount: 20000, minOrderTotal: 50000 },
      { id: 'topping', label: 'Free topping', probability: 15, rewardType: 'VOUCHER', discountAmount: 5000, maxDiscount: 5000, minOrderTotal: 30000 },
      { id: 'off-20', label: '20% OFF', probability: 10, rewardType: 'VOUCHER', discountPercent: 20, maxDiscount: 30000, minOrderTotal: 50000 },
      { id: 'try-again', label: 'Try again', probability: 15, rewardType: 'NONE' },
      { id: 'free-drink', label: 'Free drink', probability: 5, rewardType: 'VOUCHER', discountAmount: 35000, maxDiscount: 35000, minOrderTotal: 35000 },
      { id: 'points-50', label: '50 points', probability: 15, rewardType: 'POINTS', points: 50 },
      { id: 'off-15', label: '15% OFF', probability: 15, rewardType: 'VOUCHER', discountPercent: 15, maxDiscount: 25000, minOrderTotal: 50000 },
      { id: 'size-up', label: 'Free size up', probability: 10, rewardType: 'VOUCHER', discountAmount: 5000, maxDiscount: 5000, minOrderTotal: 30000 },
    ],
  } }, { upsert: true });

  const rewards = [
    { code: 'POINTS-200', title: 'Voucher giảm 10.000đ', description: 'Áp dụng cho đơn từ 30.000đ', pointsCost: 200, discountAmount: 10000, maxDiscount: 10000, minOrderTotal: 30000, validityDays: 30 },
    { code: 'POINTS-500', title: 'Voucher giảm 25.000đ', description: 'Áp dụng cho đơn từ 60.000đ', pointsCost: 500, discountAmount: 25000, maxDiscount: 25000, minOrderTotal: 60000, validityDays: 30 },
  ];
  for (const reward of rewards) await Reward.updateOne({ code: reward.code }, { $set: reward, $setOnInsert: { isActive: true } }, { upsert: true });

  await mongoose.disconnect();
  process.stdout.write('Demo branch, lucky wheel, and point rewards are ready.\n');
}

seedDemoData().catch(async (error) => {
  process.stderr.write(`${error.message}\n`);
  await mongoose.disconnect().catch(() => {});
  process.exitCode = 1;
});
