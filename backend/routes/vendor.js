const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticate, authorize } = require('../middleware/authMiddleware');

// =======================================
// Get vendor profile (owner only)
// =======================================
router.get('/my', authenticate, authorize(['vendor']), (req, res) => {
  const sql = 'SELECT * FROM vendors WHERE user_id = ?';
  db.query(sql, [req.user.id], (err, results) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (results.length === 0) return res.status(404).json({ error: 'ไม่พบข้อมูลร้าน' });
    res.json(results[0]);
  });
});

// =======================================
// Update vendor info (owner only)
// =======================================
router.put('/my', authenticate, authorize(['vendor']), (req, res) => {
  const { name, contact, address } = req.body;

  if (!name || !contact || !address) {
    return res.status(400).json({ error: 'กรุณากรอกข้อมูลให้ครบ' });
  }

  const sql = 'UPDATE vendors SET name = ?, contact = ?, address = ? WHERE user_id = ?';
  db.query(sql, [name, contact, address, req.user.id], (err, result) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (result.affectedRows === 0) return res.status(404).json({ error: 'ไม่พบร้านที่ต้องการอัพเดท' });
    res.json({ message: 'อัพเดทร้านสำเร็จ' });
  });
});

// =======================================
// Vendor view own bookings
// =======================================
router.get('/my-bookings', authenticate, authorize(['vendor']), (req, res) => {
  const sql = `
    SELECT b.*, u.name AS customer_name, u.phone AS customer_phone,
         c.name AS car_name, v.name AS vendor_name
  FROM bookings b
  JOIN users u ON b.user_id = u.id
  JOIN cars c ON b.car_id = c.id
  JOIN vendors v ON c.vendor_id = v.id
  WHERE c.vendor_id IN (SELECT id FROM vendors WHERE user_id = ?)
  ORDER BY b.created_at DESC
`;
  db.query(sql, [req.user.id], (err, results) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json(results);
  });
});

// =======================================
// Vendor view payments for their bookings
// =======================================
router.get('/my-payments', authenticate, authorize(['vendor']), (req, res) => {
  const sql = `
    SELECT p.id, p.transaction_id, p.payment_method, p.amount, p.payment_status, p.created_at,
           b.id AS booking_id, b.status AS booking_status, u.name AS customer_name
    FROM payments p
    JOIN bookings b ON p.booking_id = b.id
    JOIN users u ON b.user_id = u.id
    WHERE b.vendor_id = (SELECT id FROM vendors WHERE user_id = ?)
    ORDER BY p.created_at DESC
  `;
  db.query(sql, [req.user.id], (err, results) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json(results);
  });
});

module.exports = router;
