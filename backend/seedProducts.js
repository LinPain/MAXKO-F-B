const mongoose = require('mongoose');
require('dotenv').config();

const Product = require('./src/models/Product');

const products = [
  {
    id: 'prod-lg-01',
    name: 'Hồng Trà Sữa',
    description: 'Hồng trà kết hợp sữa thơm béo.',
    price: 35000,
    imageUrl: '',
    category: 'Trà sữa',
    isAvailable: true,

    sizes: [
      { name: 'M', extraPrice: 0, isDefault: true },
      { name: 'L', extraPrice: 5000 },
    ],

    sugarLevels: [
      { name: '0%', extraPrice: 0 },
      { name: '50%', extraPrice: 0 },
      { name: '100%', extraPrice: 0 },
    ],

    iceLevels: [
      { name: 'Không đá', extraPrice: 0 },
      { name: 'Ít đá', extraPrice: 0 },
      { name: 'Bình thường', extraPrice: 0 },
    ],

    toppings: [
      { name: 'Trân châu', extraPrice: 5000 },
      { name: 'Thạch', extraPrice: 5000 },
    ],
  },

  {
    id: 'prod-lg-02',
    name: 'Trà Đào Cam Sả',
    description: 'Trà đào thanh mát kết hợp cam và sả.',
    price: 39000,
    imageUrl: '',
    category: 'Trà trái cây',
    isAvailable: true,

    sizes: [
      { name: 'M', extraPrice: 0, isDefault: true },
      { name: 'L', extraPrice: 5000 },
    ],

    sugarLevels: [
      { name: '0%', extraPrice: 0 },
      { name: '50%', extraPrice: 0 },
      { name: '100%', extraPrice: 0 },
    ],

    iceLevels: [
      { name: 'Không đá', extraPrice: 0 },
      { name: 'Ít đá', extraPrice: 0 },
      { name: 'Bình thường', extraPrice: 0 },
    ],

    toppings: [
      { name: 'Đào', extraPrice: 5000 },
      { name: 'Thạch', extraPrice: 5000 },
    ],
  },

  {
    id: 'prod-lg-03',
    name: 'Trà Sữa Matcha',
    description: 'Trà sữa matcha thơm đậm vị.',
    price: 42000,
    imageUrl: '',
    category: 'Trà sữa',
    isAvailable: true,

    sizes: [
      { name: 'M', extraPrice: 0, isDefault: true },
      { name: 'L', extraPrice: 5000 },
    ],

    sugarLevels: [
      { name: '0%', extraPrice: 0 },
      { name: '50%', extraPrice: 0 },
      { name: '100%', extraPrice: 0 },
    ],

    iceLevels: [
      { name: 'Không đá', extraPrice: 0 },
      { name: 'Ít đá', extraPrice: 0 },
      { name: 'Bình thường', extraPrice: 0 },
    ],

    toppings: [
      { name: 'Trân châu', extraPrice: 5000 },
      { name: 'Thạch', extraPrice: 5000 },
    ],
  },

  {
    id: 'prod-lg-04',
    name: 'Hồng Trà Kem Cheese',
    description: 'Hồng trà kết hợp lớp kem cheese béo mịn.',
    price: 45000,
    imageUrl: '',
    category: 'Trà',
    isAvailable: true,

    sizes: [
      { name: 'M', extraPrice: 0, isDefault: true },
      { name: 'L', extraPrice: 5000 },
    ],

    sugarLevels: [
      { name: '0%', extraPrice: 0 },
      { name: '50%', extraPrice: 0 },
      { name: '100%', extraPrice: 0 },
    ],

    iceLevels: [
      { name: 'Không đá', extraPrice: 0 },
      { name: 'Ít đá', extraPrice: 0 },
      { name: 'Bình thường', extraPrice: 0 },
    ],

    toppings: [
      { name: 'Trân châu', extraPrice: 5000 },
      { name: 'Thạch', extraPrice: 5000 },
    ],
  },
];

async function seedProducts() {
  try {
    if (!process.env.MONGODB_URI) throw new Error('Set MONGODB_URI before seeding products.');
    await mongoose.connect(process.env.MONGODB_URI);

    for (const product of products) {
      await Product.updateOne(
        { name: product.name, brandId: 'brand-legia' },
        { $set: { ...product, brandId: 'brand-legia' } },
        { upsert: true },
      );
    }
    process.stdout.write('Sample MAXKO Tea products were inserted or updated.\n');
  } catch (error) {
    process.stderr.write(`Product seed failed: ${error.message}\n`);
    process.exitCode = 1;
  } finally {
    await mongoose.disconnect().catch(() => {});
  }
}

seedProducts();
