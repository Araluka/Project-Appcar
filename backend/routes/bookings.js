const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticate, authorize } = require('../middleware/authMiddleware');

// helper: ทำ URL รูปให้เป็น absolute
const toAbsUrl = (req, url) => {
  if (!url) return url;
  if (/^https?:\/\//i.test(url)) return url;
  return `${req.protocol}://${req.get('host')}${url.startsWith('/') ? '' : '/'}${url}`;
};

// ========================= CREATE BOOKING =========================
// POST /api/bookings
router.post('/', authenticate, authorize(['customer']), (req, res) => {
  const { car_id, start_time, end_time, driver_required } = req.body;
  if (!car_id || !start_time || !end_time) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  // กันช่วงเวลาทับของรถคันเดียวกัน (pending/confirmed)
  const overlapSql = `
    SELECT 1
    FROM bookings
    WHERE car_id = ?
      AND status IN ('pending','confirmed')
      AND NOT (end_time <= ? OR start_time >= ?)
    LIMIT 1
  `;
  db.query(overlapSql, [car_id, start_time, end_time], (eOv, ovRows) => {
    if (eOv) return res.status(500).json({ error: 'Database error (overlap check)' });
    if (ovRows.length > 0) {
      return res.status(409).json({ error: 'ช่วงเวลานี้ถูกจองแล้ว' });
    }

    // หา vendor + พิกัดรถ
    const sqlVendor = 'SELECT vendor_id, location_lat, location_lng FROM cars WHERE id = ?';
    db.query(sqlVendor, [car_id], (err, rows) => {
      if (err) return res.status(500).json({ error: 'Database error (vendor lookup)' });
      if (rows.length === 0) return res.status(404).json({ error: 'Car not found' });

      const vendorId = rows[0].vendor_id;
      const carLat = rows[0].location_lat;
      const carLng = rows[0].location_lng;

      const sqlBooking = `
        INSERT INTO bookings (user_id, car_id, vendor_id, start_time, end_time, status, driver_required, created_at)
        VALUES (?, ?, ?, ?, ?, 'pending', ?, NOW())
      `;
      db.query(
        sqlBooking,
        [req.user.id, car_id, vendorId, start_time, end_time, driver_required ? 1 : 0],
        (err2, result) => {
          if (err2) return res.status(500).json({ error: 'Database error (insert booking)' });

          const bookingId = result.insertId;

          // ถ้าไม่ต้องการ driver → จบ
          if (!driver_required) {
            return res.status(201).json({
              message: 'Booking created without driver',
              booking_id: bookingId,
              driver_assigned: false
            });
          }

          // หา driver ใกล้ที่สุด (ต้องพร้อม + มีพิกัด)
          const sqlDriver = `
            SELECT d.id AS driver_id, d.user_id,
            (6371 * acos(
               cos(radians(?)) * cos(radians(d.base_lat)) *
               cos(radians(d.base_lng) - radians(?)) +
               sin(radians(?)) * sin(radians(d.base_lat))
            )) AS distance_km,
            d.service_radius_km
            FROM drivers d
            WHERE d.is_available = 1
              AND d.base_lat IS NOT NULL
              AND d.base_lng IS NOT NULL
            ORDER BY distance_km ASC
            LIMIT 3
          `;

          // ถ้ารถไม่มีพิกัด → ข้ามไประบุไม่พบคนขับ
          if (carLat == null || carLng == null) {
            db.query('UPDATE bookings SET status="no_driver_found" WHERE id=?', [bookingId]);
            return res.status(201).json({
              message: 'Booking created but car has no location; cannot auto-assign driver',
              booking_id: bookingId,
              driver_assigned: false
            });
          }

          db.query(sqlDriver, [carLat, carLng, carLat], (err3, candidates) => {
            if (err3) {
              db.query('UPDATE bookings SET status="no_driver_found" WHERE id=?', [bookingId]);
              return res.status(201).json({
                message: 'Booking created but failed to find driver',
                booking_id: bookingId,
                driver_assigned: false
              });
            }

            // กรองตามรัศมีจริง
            const pick = (candidates || []).find(r => r.distance_km != null && r.distance_km <= r.service_radius_km);
            if (!pick) {
              db.query('UPDATE bookings SET status="no_driver_found" WHERE id=?', [bookingId]);
              return res.status(201).json({
                message: 'Booking created but no driver in radius',
                booking_id: bookingId,
                driver_assigned: false
              });
            }

            // สร้าง assignment (รอคนขับกดรับ)
            const sqlAssign = `
              INSERT INTO driver_assignments (booking_id, driver_id, is_accepted)
              VALUES (?, ?, 0)
            `;
            db.query(sqlAssign, [bookingId, pick.driver_id], (err4, aRes) => {
              if (err4) {
                db.query('UPDATE bookings SET status="no_driver_found" WHERE id=?', [bookingId]);
                return res.status(201).json({
                  message: 'Booking created but failed to assign driver',
                  booking_id: bookingId,
                  driver_assigned: false
                });
              }

              // 👇 (ไม่ set bookings.driver_id ทันที — จะ set ตอน driver กดรับงานใน driverAssignments.js)
              return res.status(201).json({
                message: 'Booking created with driver candidate',
                booking_id: bookingId,
                driver_assigned: true,
                assignment_id: aRes.insertId,
                driver_candidate_id: pick.driver_id
              });
            });
          });
        }
      );
    });
  });
});

// ========================= GET MY BOOKINGS =========================
// GET /api/bookings/my
router.get('/my', authenticate, authorize(['customer']), (req, res) => {
  const sql = `
    SELECT b.id, b.start_time, b.end_time, b.status, b.driver_required,
           c.name AS car_name, c.license_plate, c.image_url, v.name AS vendor_name
    FROM bookings b
    JOIN cars c ON b.car_id = c.id
    JOIN vendors v ON b.vendor_id = v.id
    WHERE b.user_id = ?
    ORDER BY b.created_at DESC
  `;
  db.query(sql, [req.user.id], (err, rows) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    // make image absolute
    const mapped = rows.map(r => ({ ...r, image_url: toAbsUrl(req, r.image_url) }));
    res.json(mapped);
  });
});

// ========================= GET BOOKING DETAIL =========================
// GET /api/bookings/:id
router.get('/:id', authenticate, (req, res) => {
  const { id } = req.params;

  const sql = `
    SELECT b.*, 
           u.name AS customer_name, u.phone AS customer_phone,
           c.name AS car_name, c.license_plate, c.image_url,
           v.name AS vendor_name
    FROM bookings b
    JOIN users u ON b.user_id = u.id
    JOIN cars c ON b.car_id = c.id
    JOIN vendors v ON b.vendor_id = v.id
    WHERE b.id = ?
  `;
  db.query(sql, [id], (err, rows) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (rows.length === 0) return res.status(404).json({ error: 'Booking not found' });

    const row = rows[0];
    row.image_url = toAbsUrl(req, row.image_url);
    res.json(row);
  });
});

// ========================= CANCEL BOOKING =========================
// PATCH /api/bookings/:id/cancel
router.patch('/:id/cancel', authenticate, (req, res) => {
  const { id } = req.params;
  const { role, id: userId } = req.user;

  db.query('SELECT * FROM bookings WHERE id = ?', [id], (err, rows) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (rows.length === 0) return res.status(404).json({ error: 'Booking not found' });

    const booking = rows[0];

    if (role === 'customer' && booking.user_id !== userId) {
      return res.status(403).json({ error: 'Not your booking' });
    }

    if (role === 'vendor') {
      db.query('SELECT user_id FROM vendors WHERE id = ?', [booking.vendor_id], (err2, vrows) => {
        if (err2) return res.status(500).json({ error: 'Database error' });
        if (vrows.length === 0 || vrows[0].user_id !== userId) {
          return res.status(403).json({ error: 'Not your booking' });
        }
        return doCancel(id, res);
      });
    } else {
      return doCancel(id, res);
    }
  });
});

function doCancel(bookingId, res) {
  db.query('UPDATE bookings SET status="cancelled" WHERE id=?', [bookingId], (err) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json({ message: 'Booking cancelled' });
  });
}

// ========================= ADMIN: ALL BOOKINGS =========================
// GET /api/bookings/all
router.get('/all', authenticate, authorize(['admin']), (req, res) => {
  const sql = `
    SELECT b.*, u.name AS customer_name, c.name AS car_name, c.image_url, v.name AS vendor_name
    FROM bookings b
    JOIN users u ON b.user_id = u.id
    JOIN cars c ON b.car_id = c.id
    JOIN vendors v ON b.vendor_id = v.id
    ORDER BY b.created_at DESC
  `;
  db.query(sql, (err, rows) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    const mapped = rows.map(r => ({ ...r, image_url: toAbsUrl(req, r.image_url) }));
    res.json(mapped);
  });
});

module.exports = router;
