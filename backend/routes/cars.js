const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticate, authorize } = require('../middleware/authMiddleware');

// =======================================
// Vendor: Add new car
// =======================================
router.post('/', authenticate, authorize(['vendor']), (req, res) => {
  const {
    name, license_plate, image_url, seats, transmission,
    bag_small, bag_large, unlimited_mileage, price_per_day, free_cancellation,
    location_lat, location_lng
  } = req.body;

  if (!name || !license_plate || !price_per_day) {
    return res.status(400).json({ error: 'กรุณากรอกข้อมูลรถให้ครบ' });
  }

  const sql = `
    INSERT INTO cars (vendor_id, name, license_plate, image_url, seats, transmission,
      bag_small, bag_large, unlimited_mileage, price_per_day, free_cancellation,
      location_lat, location_lng, is_available)
    VALUES ((SELECT id FROM vendors WHERE user_id = ?), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
  `;

  db.query(sql, [
    req.user.id, name, license_plate, image_url || null, seats || null, transmission || null,
    bag_small || 0, bag_large || 0, unlimited_mileage || 1, price_per_day, free_cancellation || 1,
    location_lat || null, location_lng || null
  ], (err, result) => {
    if (err) {
      if (err.code === 'ER_DUP_ENTRY') {
        return res.status(409).json({ error: 'ทะเบียนรถนี้มีอยู่แล้ว' });
      }
      return res.status(500).json({ error: 'Database error' });
    }
    res.status(201).json({ message: 'เพิ่มรถสำเร็จ', carId: result.insertId });
  });
});

// =======================================
// Vendor: Update car
// =======================================
router.put('/:id', authenticate, authorize(['vendor']), (req, res) => {
  const carId = req.params.id;
  const {
    name, image_url, seats, transmission,
    bag_small, bag_large, unlimited_mileage, price_per_day, free_cancellation,
    location_lat, location_lng
  } = req.body;

  const sql = `
    UPDATE cars SET
      name = ?, image_url = ?, seats = ?, transmission = ?, bag_small = ?, bag_large = ?,
      unlimited_mileage = ?, price_per_day = ?, free_cancellation = ?, location_lat = ?, location_lng = ?
    WHERE id = ? AND vendor_id = (SELECT id FROM vendors WHERE user_id = ?)
  `;

  db.query(sql, [
    name, image_url || null, seats || null, transmission || null,
    bag_small || 0, bag_large || 0, unlimited_mileage || 1, price_per_day || 0, free_cancellation || 1,
    location_lat || null, location_lng || null, carId, req.user.id
  ], (err, result) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (result.affectedRows === 0) return res.status(404).json({ error: 'ไม่พบรถที่จะแก้ไข' });
    res.json({ message: 'อัพเดทรถสำเร็จ' });
  });
});

// =======================================
// Vendor: Delete car
// =======================================
router.delete('/:id', authenticate, authorize(['vendor']), (req, res) => {
  const carId = req.params.id;

  const sql = `
    DELETE FROM cars WHERE id = ? AND vendor_id = (SELECT id FROM vendors WHERE user_id = ?)
  `;
  db.query(sql, [carId, req.user.id], (err, result) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (result.affectedRows === 0) return res.status(404).json({ error: 'ไม่พบรถที่จะลบ' });
    res.json({ message: 'ลบรถสำเร็จ' });
  });
});

// =======================================
// Vendor: Update availability status
// =======================================
router.patch('/:id/status', authenticate, authorize(['vendor']), (req, res) => {
  const carId = req.params.id;
  const { is_available } = req.body;

  if (typeof is_available === 'undefined') {
    return res.status(400).json({ error: 'ต้องระบุสถานะรถ (is_available)' });
  }

  const sql = `
    UPDATE cars SET is_available = ? 
    WHERE id = ? AND vendor_id = (SELECT id FROM vendors WHERE user_id = ?)
  `;
  db.query(sql, [is_available ? 1 : 0, carId, req.user.id], (err, result) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (result.affectedRows === 0) return res.status(404).json({ error: 'ไม่พบรถที่จะอัพเดทสถานะ' });
    res.json({ message: 'อัพเดทสถานะรถสำเร็จ' });
  });
});

// =======================================
// Public: Search available cars
// =======================================
// routes/cars.js
router.get('/search', (req, res) => {
  const { location_lat, location_lng, transmission, seats, start_time, end_time } = req.query;

  // base query รวมชื่อร้าน + คำนวณระยะถ้าส่งพิกัดมา
  let sql = `
    SELECT
      c.*,
      v.name AS vendor_name
      ${location_lat && location_lng ? `,
      (6371 * acos(
        cos(radians(?)) * cos(radians(c.location_lat)) *
        cos(radians(c.location_lng) - radians(?)) +
        sin(radians(?)) * sin(radians(c.location_lat))
      )) AS distance_km` : ``}
    FROM cars c
    JOIN vendors v ON c.vendor_id = v.id
    WHERE c.is_available = 1
  `;
  const params = [];

  if (location_lat && location_lng) {
    params.push(location_lat, location_lng, location_lat);
    // ถ้าอยากฟิลเตอร์ว่า “ต้องมีพิกัด”:
    sql += ` AND c.location_lat IS NOT NULL AND c.location_lng IS NOT NULL`;
  }

  if (transmission) { sql += ` AND c.transmission = ?`; params.push(transmission); }
  if (seats) { sql += ` AND c.seats >= ?`; params.push(seats); }

  // TODO (optional): กันคิวทับเวลา start_time/end_time ที่ส่งมา

  if (location_lat && location_lng) {
    sql += ` ORDER BY distance_km ASC, c.price_per_day ASC`;
  } else {
    sql += ` ORDER BY c.price_per_day ASC, c.id DESC`;
  }

  db.query(sql, params, (err, results) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json(results);
  });
});


module.exports = router;
