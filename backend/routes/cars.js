const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticate, authorize } = require('../middleware/authMiddleware');
const multer = require('multer');
const path = require('path');

// helper: absolute URL
const toAbsUrl = (req, url) => {
  if (!url) return url;
  if (/^https?:\/\//i.test(url)) return url;
  return `${req.protocol}://${req.get('host')}${url.startsWith('/') ? '' : '/'}${url}`;
};

// ตั้งค่า storage ของ multer
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/cars/');
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});
const upload = multer({ storage });

// =======================================
// Public: list cars (ทุกคัน)
// =======================================
router.get('/', (req, res) => {
  const sql = `
    SELECT id, vendor_id, name, license_plate, image_url, price_per_day,
           is_available, seats, transmission, location_lat, location_lng
    FROM cars ORDER BY id DESC
  `;
  db.query(sql, [], (err, rows) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json(rows.map(r => ({ ...r, image_url: toAbsUrl(req, r.image_url) })));
  });
});

// =======================================
// Vendor: list only my cars
// =======================================
router.get('/my', authenticate, authorize(['vendor']), (req, res) => {
  const sql = `
    SELECT id, vendor_id, name, license_plate, image_url, price_per_day,
           is_available, seats, transmission, location_lat, location_lng
    FROM cars
    WHERE vendor_id = (SELECT id FROM vendors WHERE user_id = ?)
    ORDER BY id DESC
  `;
  db.query(sql, [req.user.id], (err, rows) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json(rows.map(r => ({ ...r, image_url: toAbsUrl(req, r.image_url) })));
  });
});

// =======================================
// Vendor: Add new car (JSON)
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
// Vendor: (optional) Upload car image
// =======================================
router.post('/upload-image', authenticate, authorize(['vendor']), upload.single('image'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'ไม่พบไฟล์รูป' });
  const imageUrl = '/uploads/cars/' + req.file.filename;
  res.json({ message: 'อัปโหลดรูปสำเร็จ', image_url: imageUrl });
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
router.get('/search', (req, res) => {
  const { location_lat, location_lng, transmission, seats, start_time, end_time } = req.query;

  let sql = `
    SELECT DISTINCT
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
  `;

  const params = [];

  if (start_time && end_time) {
    sql += `
      LEFT JOIN bookings b
        ON b.car_id = c.id
        AND b.status IN ('pending','confirmed')
        AND NOT (b.end_time <= ? OR b.start_time >= ?)
    `;
    params.push(start_time, end_time);
  }

  sql += ` WHERE c.is_available = 1`;

  if (location_lat && location_lng) {
    params.push(location_lat, location_lng, location_lat);
    sql += ` AND c.location_lat IS NOT NULL AND c.location_lng IS NOT NULL`;
  }

  if (transmission) { sql += ` AND c.transmission = ?`; params.push(transmission); }
  if (seats) { sql += ` AND c.seats >= ?`; params.push(seats); }

  if (start_time && end_time) {
    sql += ` AND b.id IS NULL`;
  }

  if (location_lat && location_lng) {
    sql += ` ORDER BY distance_km ASC, c.price_per_day ASC`;
  } else {
    sql += ` ORDER BY c.price_per_day ASC, c.id DESC`;
  }

  db.query(sql, params, (err, results) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json(results.map(r => ({ ...r, image_url: toAbsUrl(req, r.image_url) })));
  });
});

module.exports = router;
