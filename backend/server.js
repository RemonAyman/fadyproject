require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// Models
const User = require('./models/User');
const Craftsman = require('./models/Craftsman');
const Booking = require('./models/Booking');
const Todo = require('./models/Todo');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Database Connection
const MONGODB_URI = process.env.MONGODB_URI;
mongoose.connect(MONGODB_URI)
  .then(() => {
    console.log('✅ Connected to MongoDB Atlas');
    seedAdmin();
  })
  .catch(err => {
    console.error('❌ MongoDB Connection Error:', err);
  });

// Seed Admin Account
async function seedAdmin() {
  try {
    const adminEmail = 'admin@gmail.com';
    const adminUser = await User.findOne({ email: adminEmail });
    
    if (!adminUser) {
      const hashedPassword = await bcrypt.hash('admin123', 10);
      const newAdmin = new User({
        name: 'مدير النظام',
        email: adminEmail,
        phone: '01000000000',
        city: 'القاهرة',
        address: 'مقر الإدارة الرئيسي',
        password: hashedPassword,
        userType: 'admin'
      });
      await newAdmin.save();
      console.log('👑 Admin account successfully seeded (admin@gmail.com / admin123)');
    } else {
      console.log('👑 Admin account already exists in database');
    }
  } catch (error) {
    console.error('❌ Failed to seed Admin account:', error);
  }
}

// =============================================================================
// AUTH ROUTES
// =============================================================================

// Login endpoint for users, craftsmen, and admins
app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'يرجى إدخال البريد الإلكتروني وكلمة المرور' });
  }

  try {
    const normalizedEmail = email.trim().toLowerCase();
    
    // 1. Search in Users collection (includes regular customers and admins)
    let account = await User.findOne({ email: normalizedEmail });
    let type = account ? account.userType : null;

    // 2. If not found, search in Craftsmen collection
    if (!account) {
      account = await Craftsman.findOne({ email: normalizedEmail });
      if (account) {
        type = 'craftsman';
      }
    }

    if (!account) {
      return res.status(404).json({ error: 'البريد الإلكتروني غير مسجل' });
    }

    // Compare passwords
    const isMatch = await bcrypt.compare(password, account.password);
    if (!isMatch) {
      return res.status(400).json({ error: 'كلمة المرور غير صحيحة' });
    }

    // Generate JWT
    const token = jwt.sign(
      { id: account._id, email: account.email, userType: type },
      process.env.JWT_SECRET || 'herafy_secret_key',
      { expiresIn: '30d' }
    );

    res.json({
      token,
      userId: account._id,
      userType: type,
      name: account.name,
      email: account.email
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'حدث خطأ أثناء تسجيل الدخول' });
  }
});

// Register standard customer
app.post('/api/auth/register-user', async (req, res) => {
  const { name, email, phone, city, address, password } = req.body;
  
  if (!name || !email || !phone || !city || !password) {
    return res.status(400).json({ error: 'جميع الحقول الأساسية مطلوبة' });
  }

  try {
    const normalizedEmail = email.trim().toLowerCase();
    
    // Check if email already registered anywhere
    const userExists = await User.findOne({ email: normalizedEmail });
    const craftsmanExists = await Craftsman.findOne({ email: normalizedEmail });

    if (userExists || craftsmanExists) {
      return res.status(400).json({ error: 'البريد الإلكتروني مستخدم بالفعل' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = new User({
      name: name.trim(),
      email: normalizedEmail,
      phone: phone.trim(),
      city: city.trim(),
      address: address ? address.trim() : '',
      password: hashedPassword,
      userType: 'customer'
    });

    await newUser.save();

    const token = jwt.sign(
      { id: newUser._id, email: newUser.email, userType: 'customer' },
      process.env.JWT_SECRET || 'herafy_secret_key',
      { expiresIn: '30d' }
    );

    res.status(201).json({
      token,
      userId: newUser._id,
      userType: 'customer',
      name: newUser.name,
      email: newUser.email
    });

  } catch (error) {
    console.error('User registration error:', error);
    res.status(500).json({ error: 'حدث خطأ أثناء إنشاء حساب المستخدم' });
  }
});

// Register craftsman
app.post('/api/auth/register-craftsman', async (req, res) => {
  const { name, email, phone, category, price, experience, password, city, address } = req.body;

  if (!name || !email || !phone || !category || !price || !experience || !password) {
    return res.status(400).json({ error: 'جميع الحقول الأساسية مطلوبة' });
  }

  try {
    const normalizedEmail = email.trim().toLowerCase();
    
    const userExists = await User.findOne({ email: normalizedEmail });
    const craftsmanExists = await Craftsman.findOne({ email: normalizedEmail });

    if (userExists || craftsmanExists) {
      return res.status(400).json({ error: 'البريد الإلكتروني مستخدم بالفعل' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const newCraftsman = new Craftsman({
      name: name.trim(),
      email: normalizedEmail,
      phone: phone.trim(),
      category: category.trim(),
      price: parseFloat(price),
      experience: parseInt(experience),
      password: hashedPassword,
      isAvailable: true,
      rating: 5.0,
      userType: 'craftsman',
      city: city ? city.trim() : '',
      address: address ? address.trim() : ''
    });

    await newCraftsman.save();

    const token = jwt.sign(
      { id: newCraftsman._id, email: newCraftsman.email, userType: 'craftsman' },
      process.env.JWT_SECRET || 'herafy_secret_key',
      { expiresIn: '30d' }
    );

    res.status(201).json({
      token,
      userId: newCraftsman._id,
      userType: 'craftsman',
      name: newCraftsman.name,
      email: newCraftsman.email
    });

  } catch (error) {
    console.error('Craftsman registration error:', error);
    res.status(500).json({ error: 'حدث خطأ أثناء إنشاء حساب الحرفي' });
  }
});

// =============================================================================
// CRAFTSMEN PROFILE AND DISCOVERY ROUTES
// =============================================================================

// Get all craftsmen with optional filters and sorting
app.get('/api/craftsmen', async (req, res) => {
  try {
    const { category, city, minRating, maxPrice, isAvailable, search, sortBy } = req.query;
    
    // Construct query object
    const queryObj = {};
    
    if (category) {
      queryObj.category = category.trim();
    }
    
    if (city) {
      queryObj.city = new RegExp(`^${city.trim()}$`, 'i');
    }
    
    if (minRating) {
      queryObj.rating = { $gte: parseFloat(minRating) };
    }
    
    if (maxPrice) {
      queryObj.price = { $lte: parseFloat(maxPrice) };
    }
    
    if (isAvailable !== undefined) {
      queryObj.isAvailable = isAvailable === 'true';
    }
    
    if (search) {
      const searchRegex = new RegExp(search.trim(), 'i');
      queryObj.$or = [
        { name: searchRegex },
        { category: searchRegex },
        { city: searchRegex },
        { address: searchRegex },
        { bio: searchRegex }
      ];
    }
    
    // Construct sort options
    let sortObj = { rating: -1 }; // Default: highest rating first
    if (sortBy === 'price') {
      sortObj = { price: 1 }; // Lowest price first
    } else if (sortBy === 'experience') {
      sortObj = { experience: -1 }; // Highest experience first
    } else if (sortBy === 'rating') {
      sortObj = { rating: -1 };
    }
    
    const list = await Craftsman.find(queryObj, '-password').sort(sortObj);
    res.json(list);
  } catch (error) {
    console.error('Fetch craftsmen error:', error);
    res.status(500).json({ error: 'فشل في جلب قائمة الحرفيين' });
  }
});

// Get single craftsman details
app.get('/api/craftsmen/:id', async (req, res) => {
  try {
    const craftsman = await Craftsman.findById(req.params.id, '-password');
    if (!craftsman) {
      return res.status(404).json({ error: 'الحرفي غير موجود' });
    }
    res.json(craftsman);
  } catch (error) {
    res.status(500).json({ error: 'فشل في جلب بيانات الحرفي' });
  }
});

// Update craftsman profile
app.put('/api/craftsmen/:id', async (req, res) => {
  const { name, phone, category, price, experience, isAvailable, photoUrl, city, address, bio, services, completedJobs } = req.body;
  try {
    const updatedData = {};
    if (name !== undefined) updatedData.name = name;
    if (phone !== undefined) updatedData.phone = phone;
    if (category !== undefined) updatedData.category = category;
    if (price !== undefined) updatedData.price = parseFloat(price);
    if (experience !== undefined) updatedData.experience = parseInt(experience);
    if (isAvailable !== undefined) updatedData.isAvailable = isAvailable;
    if (photoUrl !== undefined) updatedData.photoUrl = photoUrl;
    if (city !== undefined) updatedData.city = city.trim();
    if (address !== undefined) updatedData.address = address.trim();
    if (bio !== undefined) updatedData.bio = bio.trim();
    if (services !== undefined) updatedData.services = services;
    if (completedJobs !== undefined) updatedData.completedJobs = parseInt(completedJobs);

    const craftsman = await Craftsman.findByIdAndUpdate(
      req.params.id,
      { $set: updatedData },
      { new: true, runValidators: true }
    ).select('-password');

    if (!craftsman) {
      return res.status(404).json({ error: 'الحرفي غير موجود' });
    }

    res.json(craftsman);
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: 'فشل في تعديل البيانات' });
  }
});

// =============================================================================
// USER PROFILE ROUTES
// =============================================================================

// Get single user profile
app.get('/api/users/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id, '-password');
    if (!user) {
      return res.status(404).json({ error: 'المستخدم غير موجود' });
    }
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: 'فشل في جلب بيانات العميل' });
  }
});

// Update user profile
app.put('/api/users/:id', async (req, res) => {
  const { name, phone, city, address } = req.body;
  try {
    const updatedData = {};
    if (name !== undefined) updatedData.name = name;
    if (phone !== undefined) updatedData.phone = phone;
    if (city !== undefined) updatedData.city = city;
    if (address !== undefined) updatedData.address = address;

    const user = await User.findByIdAndUpdate(
      req.params.id,
      { $set: updatedData },
      { new: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({ error: 'المستخدم غير موجود' });
    }

    res.json(user);
  } catch (error) {
    res.status(500).json({ error: 'فشل في تعديل بيانات العميل' });
  }
});

// =============================================================================
// BOOKINGS ROUTES
// =============================================================================

// Create a new booking
app.post('/api/bookings', async (req, res) => {
  try {
    const booking = new Booking(req.body);
    await booking.save();
    res.status(201).json(booking);
  } catch (error) {
    console.error('Create booking error:', error);
    res.status(400).json({ error: 'فشل في إنشاء الحجز، تحقق من البيانات: ' + error.message });
  }
});

// List bookings for a user
app.get('/api/bookings/user/:userId', async (req, res) => {
  try {
    const list = await Booking.find({ customerId: req.params.userId }).sort({ createdAt: -1 });
    res.json(list);
  } catch (error) {
    res.status(500).json({ error: 'فشل في تحميل الحجوزات' });
  }
});

// List bookings for a craftsman
app.get('/api/bookings/craftsman/:craftsmanId', async (req, res) => {
  try {
    const list = await Booking.find({ craftsmanId: req.params.craftsmanId }).sort({ createdAt: -1 });
    res.json(list);
  } catch (error) {
    res.status(500).json({ error: 'فشل في تحميل حجوزات الحرفي' });
  }
});

// Update booking status
app.put('/api/bookings/:id/status', async (req, res) => {
  const { status } = req.body;
  if (!status) {
    return res.status(400).json({ error: 'الحالة مطلوبة' });
  }
  try {
    const booking = await Booking.findByIdAndUpdate(
      req.params.id,
      { $set: { status } },
      { new: true }
    );
    if (!booking) {
      return res.status(404).json({ error: 'الحجز غير موجود' });
    }
    res.json(booking);
  } catch (error) {
    res.status(500).json({ error: 'فشل في تحديث حالة الحجز' });
  }
});

// =============================================================================
// TODO ROUTES
// =============================================================================

// Get todos for user
app.get('/api/todos/user/:userId', async (req, res) => {
  try {
    const list = await Todo.find({ userId: req.params.userId }).sort({ createdAt: -1 });
    res.json(list);
  } catch (error) {
    res.status(500).json({ error: 'فشل في جلب المهام' });
  }
});

// Create todo
app.post('/api/todos', async (req, res) => {
  const { userId, title } = req.body;
  if (!userId || !title) {
    return res.status(400).json({ error: 'البيانات غير مكتملة' });
  }
  try {
    const todo = new Todo({ userId, title, completed: false });
    await todo.save();
    res.status(201).json(todo);
  } catch (error) {
    res.status(500).json({ error: 'فشل في إضافة المهمة' });
  }
});

// Update todo
app.put('/api/todos/:id', async (req, res) => {
  const { title, completed } = req.body;
  try {
    const updatedData = {};
    if (title !== undefined) updatedData.title = title;
    if (completed !== undefined) updatedData.completed = completed;

    const todo = await Todo.findByIdAndUpdate(
      req.params.id,
      { $set: updatedData },
      { new: true }
    );
    if (!todo) {
      return res.status(404).json({ error: 'المهمة غير موجودة' });
    }
    res.json(todo);
  } catch (error) {
    res.status(500).json({ error: 'فشل في تعديل المهمة' });
  }
});

// Delete todo
app.delete('/api/todos/:id', async (req, res) => {
  try {
    const todo = await Todo.findByIdAndDelete(req.params.id);
    if (!todo) {
      return res.status(404).json({ error: 'المهمة غير موجودة' });
    }
    res.json({ success: true, message: 'تم حذف المهمة بنجاح' });
  } catch (error) {
    res.status(500).json({ error: 'فشل في حذف المهمة' });
  }
});

// =============================================================================
// ADMIN PANEL ROUTES
// =============================================================================

// Get stats
app.get('/api/admin/stats', async (req, res) => {
  try {
    const totalUsers = await User.countDocuments({ userType: 'customer' });
    const totalCraftsmen = await Craftsman.countDocuments({});
    const totalBookings = await Booking.countDocuments({});
    
    // platform estimated revenue: sum of expectedPrice of confirmed or completed bookings
    const earningStats = await Booking.aggregate([
      { $match: { status: { $in: ['confirmed', 'completed'] } } },
      { $group: { _id: null, total: { $sum: '$expectedPrice' } } }
    ]);
    
    const estimatedRevenue = earningStats.length > 0 ? earningStats[0].total : 0;

    res.json({
      totalUsers,
      totalCraftsmen,
      totalBookings,
      estimatedRevenue
    });
  } catch (error) {
    console.error('Admin stats error:', error);
    res.status(500).json({ error: 'فشل في جلب الإحصائيات' });
  }
});

// List users
app.get('/api/admin/users', async (req, res) => {
  try {
    const list = await User.find({ userType: 'customer' }, '-password').sort({ createdAt: -1 });
    res.json(list);
  } catch (error) {
    res.status(500).json({ error: 'فشل في تحميل المستخدمين' });
  }
});

// Delete user
app.delete('/api/admin/users/:id', async (req, res) => {
  try {
    const user = await User.findByIdAndDelete(req.params.id);
    if (!user) {
      return res.status(404).json({ error: 'المستخدم غير موجود' });
    }
    res.json({ success: true, message: 'تم حذف الحساب بنجاح' });
  } catch (error) {
    res.status(500).json({ error: 'فشل في حذف الحساب' });
  }
});

// List craftsmen
app.get('/api/admin/craftsmen', async (req, res) => {
  try {
    const list = await Craftsman.find({}, '-password').sort({ createdAt: -1 });
    res.json(list);
  } catch (error) {
    res.status(500).json({ error: 'فشل في تحميل الحرفيين' });
  }
});

// Delete craftsman
app.delete('/api/admin/craftsmen/:id', async (req, res) => {
  try {
    const craftsman = await Craftsman.findByIdAndDelete(req.params.id);
    if (!craftsman) {
      return res.status(404).json({ error: 'الحساب غير موجود' });
    }
    // Clean up related bookings
    await Booking.deleteMany({ craftsmanId: req.params.id });
    res.json({ success: true, message: 'تم حذف الحساب والطلبات المرتبطة بنجاح' });
  } catch (error) {
    res.status(500).json({ error: 'فشل في حذف حساب الحرفي' });
  }
});

// Verify/Approve craftsman (toggle isAvailable or ratings)
app.put('/api/admin/craftsmen/:id/approve', async (req, res) => {
  try {
    const craftsman = await Craftsman.findById(req.params.id);
    if (!craftsman) {
      return res.status(404).json({ error: 'الحرفي غير موجود' });
    }
    // Toggle status or verify (we can set rating to 5.0 as verified indicator or set special flag)
    // Here we can simply toggle isAvailable as approved status
    craftsman.isAvailable = !craftsman.isAvailable;
    await craftsman.save();
    
    res.json({ success: true, isAvailable: craftsman.isAvailable });
  } catch (error) {
    res.status(500).json({ error: 'فشل في تعديل حالة الحرفي' });
  }
});

// List all bookings
app.get('/api/admin/bookings', async (req, res) => {
  try {
    const list = await Booking.find({}).sort({ createdAt: -1 });
    res.json(list);
  } catch (error) {
    res.status(500).json({ error: 'فشل في تحميل قائمة الحجوزات' });
  }
});

// Run server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Express server running on port ${PORT}`);
});
