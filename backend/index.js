const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const db = require('./db');

// ----------- const ------------ //
const authRoutes = require('./routes/auth');
const authenticate = require('./middleware/authMiddleware'); // ✅ ต้องใช้ ./ แทน ../ เพราะอยู่ใน root เดียวกัน
const vendorRoutes = require('./routes/vendor');
const carRoutes = require('./routes/cars');
const bookingRoutes = require('./routes/bookings');
const driverRoutes = require('./routes/driver');
const notificationRoutes = require('./routes/notifications');
const paymentRoutes = require('./routes/payment'); // เพิ่มการเชื่อมโยง API การชำระเงิน

const app = express();
const PORT = 3000;

app.use(cors());
app.use(bodyParser.json());

// ----------- use ------------ //
app.use('/api', authRoutes);
app.use('/api', vendorRoutes);
app.use('/api/cars', carRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/driver', driverRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api', paymentRoutes); // เชื่อมโยงเส้นทางชำระเงิน

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
