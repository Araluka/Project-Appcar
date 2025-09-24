const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const db = require('./db');

// ----------- import routes ------------ //
const authRoutes = require('./routes/auth');
const { authenticate } = require('./middleware/authMiddleware');
const vendorRoutes = require('./routes/vendor');
const carRoutes = require('./routes/cars');
const bookingRoutes = require('./routes/bookings');
const driverRoutes = require('./routes/drivers');
const driverAssignmentRoutes = require('./routes/driverAssignments');
const notificationRoutes = require('./routes/notifications');
const paymentRoutes = require('./routes/payments');
const receiptRoutes = require('./routes/receipts');
const userRoutes = require('./routes/users');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(bodyParser.json());

// ----------- use routes ------------ //
app.use('/api', authRoutes);
app.use('/api/users', userRoutes); // admin จัดการผู้ใช้
app.use('/api/vendor', vendorRoutes);
app.use('/api/cars', carRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/drivers', driverRoutes);
app.use('/api/driver-assignments', driverAssignmentRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/receipts', receiptRoutes);

// ✅ ทดสอบ route ที่ต้อง login ก่อนถึง (เช่น /me)
app.get('/api/me', authenticate, (req, res) => {
  res.json({
    message: 'ข้อมูลผู้ใช้ที่เข้าสู่ระบบ',
    user: req.user
  });
});

app.get('/', (req, res) => {
  res.send('🚗 Car Booking API is running!');
});

app.listen(PORT, () => {
  console.log(`✅ Server is running on http://localhost:${PORT}`);
});
