const express = require('express');
const router = express.Router();
const db = require('../db');

// ✅ สมัครผู้ใช้
router.post('/register', (req, res) => {
  const { name, email, password, phone } = req.body;

  if (!name || !email || !password || !phone) {
    return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบถ้วน' });
  }

  const sql = 'INSERT INTO users (name, email, password, phone) VALUES (?, ?, ?, ?)';
  db.query(sql, [name, email, password, phone], (err, result) => {
    if (err) {
      if (err.code === 'ER_DUP_ENTRY') {
        return res.status(409).json({ message: 'อีเมลนี้มีผู้ใช้งานแล้ว' });
      }
      return res.status(500).json({ message: 'เกิดข้อผิดพลาดในการสมัคร' });
    }
    res.status(201).json({ message: 'สมัครสำเร็จ', userId: result.insertId });
  });
});

module.exports = router;
