const express = require('express');
const router = express.Router();
const db = require('../db');
const authenticate = require('../middleware/authMiddleware');

// ✅ เพิ่มรถ (เฉพาะ vendor)
router.post('/', authenticate, (req, res) => {
  const {
    name,
    license_plate,
    location_lat,
    location_lng,
    image_url,
    seats,
    transmission,
    bag_small,
    bag_large,
    unlimited_mileage,
    price_per_day,
    free_cancellation
  } = req.body;

  const userId = req.user.id;

  // เฉพาะ vendor เท่านั้น
  if (req.user.role !== 'vendor') {
    return res.status(403).json({ message: 'เฉพาะร้านเท่านั้นที่เพิ่มรถได้' });
  }

  // ดึง vendor_id ของ user นี้
  const getVendorSql = 'SELECT id FROM vendors WHERE user_id = ?';
  db.query(getVendorSql, [userId], (err, results) => {
    if (err || results.length === 0) {
      return res.status(400).json({ message: 'ไม่พบร้านของผู้ใช้นี้' });
    }

    const vendorId = results[0].id;

    const insertSql = `
      INSERT INTO cars (
        vendor_id, name, license_plate, is_available,
        location_lat, location_lng, image_url, seats, transmission,
        bag_small, bag_large, unlimited_mileage,
        price_per_day, free_cancellation
      ) VALUES (?, ?, ?, true, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;

    const values = [
      vendorId, name, license_plate,
      location_lat, location_lng, image_url,
      seats, transmission, bag_small, bag_large,
      unlimited_mileage, price_per_day, free_cancellation
    ];

    db.query(insertSql, values, (err2, result) => {
      if (err2) {
        return res.status(500).json({ message: 'ไม่สามารถเพิ่มรถได้', error: err2 });
      }
      res.status(201).json({ message: 'เพิ่มรถสำเร็จ', carId: result.insertId });
    });
  });
});


// ✅ ดูรถของร้าน (เฉพาะ vendor)
router.get('/my', authenticate, (req, res) => {
  const userId = req.user.id;

  if (req.user.role !== 'vendor') {
    return res.status(403).json({ message: 'เฉพาะร้านเท่านั้นที่ดูรถตัวเองได้' });
  }

  const sql = `
    SELECT c.* FROM cars c
    JOIN vendors v ON c.vendor_id = v.id
    WHERE v.user_id = ?
  `;
  db.query(sql, [userId], (err, results) => {
    if (err) return res.status(500).json({ message: 'ดึงข้อมูลไม่สำเร็จ' });
    res.json({ cars: results });
  });
});

// ✅ แก้ไขข้อมูลรถ (เฉพาะเจ้าของร้าน)
router.patch('/:id', authenticate, (req, res) => {
  const carId = req.params.id;
  const userId = req.user.id;

  if (req.user.role !== 'vendor') {
    return res.status(403).json({ message: 'เฉพาะร้านเท่านั้นที่แก้ไขรถได้' });
  }

  const getVendorSql = 'SELECT id FROM vendors WHERE user_id = ?';
  db.query(getVendorSql, [userId], (err, vendorResults) => {
    if (err || vendorResults.length === 0) {
      return res.status(400).json({ message: 'ไม่พบร้านของผู้ใช้นี้' });
    }

    const vendorId = vendorResults[0].id;

    // ตรวจสอบว่าเป็นรถของร้านนี้
    const checkSql = 'SELECT * FROM cars WHERE id = ? AND vendor_id = ?';
    db.query(checkSql, [carId, vendorId], (err2, carResults) => {
      if (err2 || carResults.length === 0) {
        return res.status(404).json({ message: 'ไม่พบรถ หรือรถไม่เป็นของร้านนี้' });
      }

      // สร้าง SQL แก้ไขแบบ dynamic จาก field ที่ส่งมา
      const allowedFields = [
        'name', 'license_plate', 'location_lat', 'location_lng', 'image_url',
        'seats', 'transmission', 'bag_small', 'bag_large',
        'unlimited_mileage', 'price_per_day', 'free_cancellation', 'is_available'
      ];
      const fields = [];
      const values = [];

      allowedFields.forEach((field) => {
        if (req.body[field] !== undefined) {
          fields.push(`${field} = ?`);
          values.push(req.body[field]);
        }
      });

      if (fields.length === 0) {
        return res.status(400).json({ message: 'ไม่มีข้อมูลที่จะแก้ไข' });
      }

      const updateSql = `UPDATE cars SET ${fields.join(', ')} WHERE id = ?`;
      values.push(carId);

      db.query(updateSql, values, (err3, result) => {
        if (err3) {
          return res.status(500).json({ message: 'เกิดข้อผิดพลาดในการอัปเดตรถ', error: err3 });
        }
        res.json({ message: 'แก้ไขข้อมูลรถเรียบร้อยแล้ว' });
      });
    });
  });
});
// ✅ ค้นหารถว่างตามวัน + พิกัด + รัศมี
router.get('/search', (req, res) => {
  const { date, start, radius = 10 } = req.query;

  if (!date || !start) {
    return res.status(400).json({ message: 'ต้องระบุ date และ start (lat,lng)' });
  }

  const [lat, lng] = start.split(',').map(Number);
  const searchRadius = Number(radius);

  const sql = `
    SELECT c.*, (
      6371 * acos(
        cos(radians(?)) * cos(radians(c.location_lat)) *
        cos(radians(c.location_lng) - radians(?)) +
        sin(radians(?)) * sin(radians(c.location_lat))
      )
    ) AS distance_km
    FROM cars c
    WHERE c.is_available = true
      AND NOT EXISTS (
        SELECT 1 FROM bookings b
        WHERE b.car_id = c.id AND b.booking_date = ?
      )
    HAVING distance_km <= ?
    ORDER BY distance_km ASC
  `;

  const params = [lat, lng, lat, date, searchRadius];

  db.query(sql, params, (err, results) => {
    if (err) {
      return res.status(500).json({ message: 'เกิดข้อผิดพลาดในการค้นหา', error: err });
    }
    res.json({ cars: results });
  });
});

module.exports = router;
