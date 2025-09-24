const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticate, authorize } = require('../middleware/authMiddleware');

/**
 * GET /api/receipts/my
 * ลูกค้า (customer) ดูใบเสร็จของตัวเอง
 * เวนเดอร์ (vendor) ดูใบเสร็จของร้านตัวเอง
 * ไดรเวอร์ (driver) ปกติไม่ต้องใช้ แต่ให้ 403 ไว้ชัดเจน
 */
router.get('/my', authenticate, (req, res) => {
  const { id: userId, role } = req.user;

  if (role === 'customer') {
    const sql = `
      SELECT r.*, b.id AS booking_id, b.booking_date, b.start_time, b.end_time,
             c.name AS car_name, v.name AS vendor_name
      FROM receipts r
      JOIN bookings b ON r.booking_id = b.id
      JOIN cars c ON b.car_id = c.id
      LEFT JOIN vendors v ON b.vendor_id = v.id
      WHERE b.user_id = ?
      ORDER BY r.created_at DESC
    `;
    return db.query(sql, [userId], (err, rows) => {
      if (err) return res.status(500).json({ error: 'Database error' });
      res.json(rows);
    });
  }

  if (role === 'vendor') {
    // ใบเสร็จของ booking ที่เป็นรถในร้านของ vendor นี้
    const sql = `
      SELECT r.*, b.id AS booking_id, b.booking_date, b.start_time, b.end_time,
             c.name AS car_name, v.name AS vendor_name
      FROM receipts r
      JOIN bookings b ON r.booking_id = b.id
      JOIN cars c ON b.car_id = c.id
      JOIN vendors v ON b.vendor_id = v.id
      WHERE v.user_id = ?
      ORDER BY r.created_at DESC
    `;
    return db.query(sql, [userId], (err, rows) => {
      if (err) return res.status(500).json({ error: 'Database error' });
      res.json(rows);
    });
  }

  return res.status(403).json({ error: 'คุณไม่มีสิทธิ์เข้าถึง' });
});

/**
 * GET /api/receipts/all
 * แอดมินดูใบเสร็จทั้งหมด
 */
router.get('/all', authenticate, authorize(['admin']), (req, res) => {
  const sql = `
    SELECT r.*,
           b.id AS booking_id, b.booking_date, b.start_time, b.end_time, b.status AS booking_status,
           u.name AS customer_name, u.email AS customer_email,
           c.name AS car_name, c.license_plate,
           v.name AS vendor_name
    FROM receipts r
    JOIN bookings b ON r.booking_id = b.id
    JOIN users u ON b.user_id = u.id
    JOIN cars c ON b.car_id = c.id
    LEFT JOIN vendors v ON b.vendor_id = v.id
    ORDER BY r.created_at DESC
  `;
  db.query(sql, (err, rows) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json(rows);
  });
});

/**
 * GET /api/receipts/:id
 * แสดงรายละเอียดใบเสร็จตาม id:
 * - admin ดูได้ทุกใบ
 * - customer: ดูเฉพาะของตัวเอง
 * - vendor: ดูเฉพาะของร้านตัวเอง
 */
router.get('/:id', authenticate, (req, res) => {
  const receiptId = req.params.id;
  const { id: userId, role } = req.user;

  const base = `
    SELECT r.*,
           b.id AS booking_id, b.user_id AS customer_id, b.vendor_id,
           u.name AS customer_name, u.email AS customer_email,
           c.name AS car_name, c.license_plate,
           v.name AS vendor_name, v.user_id AS vendor_user_id
    FROM receipts r
    JOIN bookings b ON r.booking_id = b.id
    JOIN users u ON b.user_id = u.id
    JOIN cars c ON b.car_id = c.id
    LEFT JOIN vendors v ON b.vendor_id = v.id
    WHERE r.id = ?
  `;

  db.query(base, [receiptId], (err, rows) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (rows.length === 0) return res.status(404).json({ message: 'ไม่พบใบเสร็จ' });

    const rc = rows[0];

    if (role === 'admin') return res.json(rc);
    if (role === 'customer' && rc.customer_id === userId) return res.json(rc);
    if (role === 'vendor' && rc.vendor_user_id === userId) return res.json(rc);

    return res.status(403).json({ error: 'คุณไม่มีสิทธิ์เข้าถึง' });
  });
});

module.exports = router;
