const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticate, authorize } = require('../middleware/authMiddleware');

// ========================= CREATE BOOKING =========================
// POST /api/bookings
router.post('/', authenticate, authorize(['customer']), (req, res) => {
  const { car_id, start_time, end_time, driver_required } = req.body;
  if (!car_id || !start_time || !end_time) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  // หา vendor_id
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
          return res.json({ message: 'Booking created without driver', booking_id: bookingId });
        }

        // หา driver ใกล้ที่สุด
        const sqlDriver = `
          SELECT d.id, d.user_id, (
            6371 * acos(
              cos(radians(?)) * cos(radians(d.base_lat)) *
              cos(radians(d.base_lng) - radians(?)) +
              sin(radians(?)) * sin(radians(d.base_lat))
            )
          ) AS distance_km
          FROM drivers d
          WHERE d.is_available = 1
          HAVING distance_km <= d.service_radius_km
          ORDER BY distance_km ASC
          LIMIT 1
        `;
        db.query(sqlDriver, [carLat, carLng, carLat], (err3, drivers) => {
          if (err3) return res.status(500).json({ error: 'Database error (find driver)' });

          if (drivers.length === 0) {
            return res.json({
              message: 'Booking created but no driver found',
              booking_id: bookingId,
              driver_assigned: false,
            });
          }

          const driverId = drivers[0].id;
          const sqlAssign = `
            INSERT INTO driver_assignments (booking_id, driver_id, is_accepted)
            VALUES (?, ?, 0)
          `;
          db.query(sqlAssign, [bookingId, driverId], (err4) => {
            if (err4) return res.status(500).json({ error: 'Database error (assign driver)' });

            return res.json({
              message: 'Booking created with driver',
              booking_id: bookingId,
              driver_assigned: true,
              driver_id: driverId,
            });
          });
        });
      }
    );
  });
});

// ========================= GET MY BOOKINGS =========================
// GET /api/bookings/my
router.get('/my', authenticate, authorize(['customer']), (req, res) => {
  const sql = `
    SELECT b.id, b.start_time, b.end_time, b.status, b.driver_required,
           c.name AS car_name, v.name AS vendor_name
    FROM bookings b
    JOIN cars c ON b.car_id = c.id
    JOIN vendors v ON b.vendor_id = v.id
    WHERE b.user_id = ?
    ORDER BY b.created_at DESC
  `;
  db.query(sql, [req.user.id], (err, rows) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json(rows);
  });
});

// ========================= GET BOOKING DETAIL =========================
// GET /api/bookings/:id
router.get('/:id', authenticate, (req, res) => {
  const { id } = req.params;

  const sql = `
    SELECT b.*, u.name AS customer_name, u.phone AS customer_phone,
           c.name AS car_name, v.name AS vendor_name
    FROM bookings b
    JOIN users u ON b.user_id = u.id
    JOIN cars c ON b.car_id = c.id
    JOIN vendors v ON c.vendor_id = v.id
    WHERE b.id = ?
  `;
  db.query(sql, [id], (err, rows) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (rows.length === 0) return res.status(404).json({ error: 'Booking not found' });
    res.json(rows[0]);
  });
});


// ========================= CANCEL BOOKING =========================
// PATCH /api/bookings/:id/cancel
router.patch('/:id/cancel', authenticate, (req, res) => {
  const { id } = req.params;
  const { role, id: userId } = req.user;

  // หา booking
  db.query('SELECT * FROM bookings WHERE id = ?', [id], (err, rows) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (rows.length === 0) return res.status(404).json({ error: 'Booking not found' });

    const booking = rows[0];

    // สิทธิ์ cancel
    if (role === 'customer' && booking.user_id !== userId) {
      return res.status(403).json({ error: 'Not your booking' });
    }
    if (role === 'vendor') {
      // เช็คว่าเป็น vendor ของรถคันนี้
      db.query('SELECT user_id FROM vendors WHERE id = ?', [booking.vendor_id], (err2, vrows) => {
        if (err2) return res.status(500).json({ error: 'Database error' });
        if (vrows.length === 0 || vrows[0].user_id !== userId) {
          return res.status(403).json({ error: 'Not your booking' });
        }
        doCancel(id, res);
      });
    } else {
      doCancel(id, res);
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
    SELECT b.*, u.name AS customer_name, c.name AS car_name, v.name AS vendor_name
    FROM bookings b
    JOIN users u ON b.user_id = u.id
    JOIN cars c ON b.car_id = c.id
    JOIN vendors v ON b.vendor_id = v.id
    ORDER BY b.created_at DESC
  `;
  db.query(sql, (err, rows) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json(rows);
  });
});

// ✅ Vendor return car
// PATCH /api/bookings/:id/return
router.patch('/:id/return', authenticate, (req, res) => {
  const { id } = req.params;
  const { role, id: userId } = req.user;

  if (role !== 'vendor') {
    return res.status(403).json({ error: 'Only vendors can return cars' });
  }

  // หา booking และเช็คว่าเป็นรถของ vendor นี้
  const sql = `
    SELECT b.*, c.vendor_id
    FROM bookings b
    JOIN cars c ON b.car_id = c.id
    WHERE b.id = ?
  `;
  db.query(sql, [id], (err, rows) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (rows.length === 0) return res.status(404).json({ error: 'Booking not found' });

    const booking = rows[0];
    db.query('SELECT user_id FROM vendors WHERE id = ?', [booking.vendor_id], (err2, vrows) => {
      if (err2) return res.status(500).json({ error: 'Database error' });
      if (vrows.length === 0 || vrows[0].user_id !== userId) {
        return res.status(403).json({ error: 'Not your booking' });
      }

      // ✅ อัพเดทสถานะเป็น completed
      db.query('UPDATE bookings SET status = "completed" WHERE id = ?', [id], (err3) => {
        if (err3) return res.status(500).json({ error: 'Database error' });
        return res.json({ message: 'Booking marked as completed', booking_id: id });
      });
    });
  });
});


module.exports = router;
