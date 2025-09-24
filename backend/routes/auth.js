const express = require('express');
const router = express.Router();
const db = require('../db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { authenticate, authorize } = require('../middleware/authMiddleware');

const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_key';

// ===============================
// Register: customer
// ===============================
router.post('/register', async (req, res) => {
  const { name, email, password, phone } = req.body;

  if (!name || !email || !password || !phone) {
    return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบถ้วน' });
  }

  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    const sql = 'INSERT INTO users (name, email, password, phone, role) VALUES (?, ?, ?, ?, "customer")';
    db.query(sql, [name, email, hashedPassword, phone], (err, result) => {
      if (err) {
        if (err.code === 'ER_DUP_ENTRY') {
          return res.status(409).json({ message: 'อีเมลนี้มีผู้ใช้งานแล้ว' });
        }
        return res.status(500).json({ message: 'เกิดข้อผิดพลาดในการสมัคร' });
      }
      const token = jwt.sign({ id: result.insertId, role: 'customer' }, JWT_SECRET, { expiresIn: '7d' });
      res.status(201).json({ message: 'สมัครผู้ใช้สำเร็จ', token, role: 'customer' });
    });
  } catch (error) {
    res.status(500).json({ message: 'เกิดข้อผิดพลาดในระบบ' });
  }
});

// ===============================
// Register: vendor
// ===============================
router.post('/register/vendor', async (req, res) => {
  const { name, email, password, phone, shopName, contact, address } = req.body;

  if (!name || !email || !password || !phone || !shopName || !contact || !address) {
    return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบ' });
  }

  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    const userSql = 'INSERT INTO users (name, email, password, phone, role) VALUES (?, ?, ?, ?, "vendor")';
    db.query(userSql, [name, email, hashedPassword, phone], (err, result) => {
      if (err) {
        if (err.code === 'ER_DUP_ENTRY') {
          return res.status(409).json({ message: 'อีเมลนี้มีผู้ใช้งานแล้ว' });
        }
        return res.status(500).json({ message: 'สมัครไม่สำเร็จ (users)' });
      }

      const userId = result.insertId;
      const vendorSql = 'INSERT INTO vendors (name, contact, address, user_id) VALUES (?, ?, ?, ?)';
      db.query(vendorSql, [shopName, contact, address, userId], (err2) => {
        if (err2) {
          return res.status(500).json({ message: 'สมัครไม่สำเร็จ (vendors)' });
        }

        const token = jwt.sign({ id: userId, role: 'vendor' }, JWT_SECRET, { expiresIn: '7d' });
        res.status(201).json({ message: 'สมัครเป็นร้านสำเร็จ', token, role: 'vendor' });
      });
    });
  } catch (error) {
    res.status(500).json({ message: 'ระบบขัดข้อง' });
  }
});

// ===============================
// Register: driver
// ===============================
router.post('/register/driver', async (req, res) => {
  const { name, email, password, phone, base_lat, base_lng, service_radius_km } = req.body;

  if (!name || !email || !password || !phone || !base_lat || !base_lng) {
    return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบ' });
  }

  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    const userSql = 'INSERT INTO users (name, email, password, phone, role) VALUES (?, ?, ?, ?, "driver")';
    db.query(userSql, [name, email, hashedPassword, phone], (err, result) => {
      if (err) {
        if (err.code === 'ER_DUP_ENTRY') {
          return res.status(409).json({ message: 'อีเมลนี้มีผู้ใช้งานแล้ว' });
        }
        return res.status(500).json({ message: 'สมัครไม่สำเร็จ (users)' });
      }

      const userId = result.insertId;
      const driverSql = 'INSERT INTO drivers (user_id, base_lat, base_lng, service_radius_km) VALUES (?, ?, ?, ?)';
      db.query(driverSql, [userId, base_lat, base_lng, service_radius_km || 10], (err2) => {
        if (err2) {
          return res.status(500).json({ message: 'สมัครไม่สำเร็จ (drivers)' });
        }

        const token = jwt.sign({ id: userId, role: 'driver' }, JWT_SECRET, { expiresIn: '7d' });
        res.status(201).json({ message: 'สมัครเป็นคนขับสำเร็จ', token, role: 'driver' });
      });
    });
  } catch (error) {
    res.status(500).json({ message: 'ระบบขัดข้อง' });
  }
});

// ===============================
// Login
// ===============================
router.post('/login', (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'กรุณากรอกอีเมลและรหัสผ่าน' });
  }

  const sql = 'SELECT * FROM users WHERE email = ?';
  db.query(sql, [email], async (err, results) => {
    if (err) return res.status(500).json({ error: 'Database error' });

    if (results.length === 0) {
      return res.status(401).json({ error: 'อีเมลหรือรหัสผ่านไม่ถูกต้อง' });
    }

    const user = results[0];
    try {
      const isMatch = await bcrypt.compare(password, user.password);
      if (!isMatch) {
        return res.status(401).json({ error: 'อีเมลหรือรหัสผ่านไม่ถูกต้อง' });
      }

      const token = jwt.sign(
        { id: user.id, email: user.email, name: user.name, role: user.role },
        JWT_SECRET,
        { expiresIn: '7d' }
      );

      res.json({
        message: 'เข้าสู่ระบบสำเร็จ',
        token,
        role: user.role,
      });

    } catch (error) {
      return res.status(500).json({ error: 'เกิดข้อผิดพลาดในการตรวจสอบรหัสผ่าน' });
    }
  });
});

// ===============================
// Profile (ทุก role ใช้ได้)
// ===============================
router.get('/profile', authenticate, async (req, res) => {
  const sql = 'SELECT id, name, email, phone, role, created_at FROM users WHERE id = ?';
  db.query(sql, [req.user.id], (err, results) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (results.length === 0) return res.status(404).json({ error: 'ไม่พบผู้ใช้' });
    res.json(results[0]);
  });
});

// ===============================
// Admin-only: list users
// ===============================
router.get('/all-users', authenticate, authorize(['admin']), (req, res) => {
  const sql = 'SELECT id, name, email, phone, role, created_at FROM users';
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json(results);
  });
});

module.exports = router;
