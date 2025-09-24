const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticate, authorize } = require('../middleware/authMiddleware');

// =======================================
// Driver: ดูโปรไฟล์ตัวเอง
// =======================================
router.get('/me', authenticate, authorize(['driver']), (req, res) => {
  const sql = 'SELECT * FROM drivers WHERE user_id = ?';
  db.query(sql, [req.user.id], (err, results) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (results.length === 0) return res.status(404).json({ message: 'ไม่พบข้อมูลคนขับ' });
    res.json(results[0]);
  });
});

// =======================================
// Driver: อัพเดทพื้นที่บริการ + รัศมี
// =======================================
router.put('/me', authenticate, authorize(['driver']), (req, res) => {
  const { base_lat, base_lng, service_radius_km, is_available } = req.body;

  const sql = `
    UPDATE drivers SET base_lat = ?, base_lng = ?, service_radius_km = ?, is_available = ?
    WHERE user_id = ?
  `;
  db.query(sql, [
    base_lat || null,
    base_lng || null,
    service_radius_km || 10,
    is_available !== undefined ? is_available : 1,
    req.user.id
  ], (err, result) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (result.affectedRows === 0) return res.status(404).json({ message: 'ไม่พบข้อมูลคนขับ' });
    res.json({ message: 'อัพเดทข้อมูลสำเร็จ' });
  });
});

// =======================================
// Driver: อัพเดทสถานะพร้อมให้บริการ (toggle)
// =======================================
router.patch('/me/status', authenticate, authorize(['driver']), (req, res) => {
  const { is_available } = req.body;
  if (typeof is_available === 'undefined') {
    return res.status(400).json({ message: 'กรุณาระบุสถานะ is_available' });
  }

  const sql = 'UPDATE drivers SET is_available = ? WHERE user_id = ?';
  db.query(sql, [is_available ? 1 : 0, req.user.id], (err, result) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (result.affectedRows === 0) return res.status(404).json({ message: 'ไม่พบข้อมูลคนขับ' });
    res.json({ message: 'อัพเดทสถานะสำเร็จ' });
  });
});

// =======================================
// Driver: ดูประวัติการให้บริการ
// =======================================
router.get('/my-history', authenticate, authorize(['driver']), (req, res) => {
  const sql = `
    SELECT b.id AS booking_id, b.booking_date, b.start_time, b.end_time, b.status,
           u.name AS customer_name, c.name AS car_name, c.license_plate
    FROM driver_assignments da
    JOIN bookings b ON da.booking_id = b.id
    JOIN users u ON b.user_id = u.id
    JOIN cars c ON b.car_id = c.id
    JOIN drivers d ON da.driver_id = d.id
    WHERE d.user_id = ?
    ORDER BY b.booking_date DESC
  `;
  db.query(sql, [req.user.id], (err, results) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json(results);
  });
});

module.exports = router;
