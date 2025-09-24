const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticate, authorize } = require('../middleware/authMiddleware');

// =======================================
// User: ดูใบเสร็จของตัวเอง
// =======================================
router.get('/my', authenticate, authorize(['customer']), (req, res) => {
  const userId = req.user.id;

  const sql = `
    SELECT r.*, b.booking_date, b.start_time, b.end_time,
           c.name AS car_name, c.license_plate, v.name AS vendor_name
    FROM receipts r
    JOIN bookings b ON r.booking_id = b.id
    JOIN cars c ON b.car_id = c.id
    JOIN vendors v ON b.vendor_id = v.id
    WHERE b.user_id = ?
    ORDER BY r.created_at DESC
  `;

  db.query(sql, [userId], (err, results) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json(results);
  });
});

// =======================================
// User: ดูใบเสร็จเดี่ยว (ตาม id)
// =======================================
router.get('/:id', authenticate, authorize(['customer']), (req, res) => {
  const receiptId = req.params.id;
  const userId = req.user.id;

  const sql = `
    SELECT r.*, b.booking_date, b.start_time, b.end_time,
           c.name AS car_name, v.name AS vendor_name
    FROM receipts r
    JOIN bookings b ON r.booking_id = b.id
    JOIN cars c ON b.car_id = c.id
    JOIN vendors v ON b.vendor_id = v.id
    WHERE r.id = ? AND b.user_id = ?
  `;

  db.query(sql, [receiptId, userId], (err, results) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (results.length === 0) return res.status(404).json({ message: 'ไม่พบใบเสร็จ' });
    res.json(results[0]);
  });
});

// =======================================
// Admin: ดูใบเสร็จทั้งหมด
router.get('/all', authenticate, authorize(['admin']), (req, res) => {
  const sql = `
    SELECT r.*, u.name AS customer_name, v.name AS vendor_name, c.name AS car_name
    FROM receipts r
    JOIN bookings b ON r.booking_id = b.id
    JOIN users u ON b.user_id = u.id
    LEFT JOIN vendors v ON b.vendor_id = v.id
    JOIN cars c ON b.car_id = c.id
    ORDER BY r.created_at DESC
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json(results);
  });
});

module.exports = router;
