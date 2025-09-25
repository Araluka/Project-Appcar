const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticate, authorize } = require('../middleware/authMiddleware');

// ---------------- CREATE BOOKING ----------------
// POST /api/bookings
router.post('/', authenticate, authorize(['customer']), (req, res) => {
  const { car_id, start_time, end_time, driver_required } = req.body;

  if (!car_id || !start_time || !end_time) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  // หา vendor_id จาก cars
  const sqlVendor = 'SELECT vendor_id FROM cars WHERE id = ?';
  db.query(sqlVendor, [car_id], (err, rows) => {
    if (err) {
      console.error('DB error (vendor lookup):', err);
      return res.status(500).json({ error: 'Database error (vendor lookup)' });
    }
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Car not found' });
    }

    const vendorId = rows[0].vendor_id;

    const sqlBooking = `
      INSERT INTO bookings (user_id, car_id, vendor_id, start_time, end_time, status, driver_required, created_at)
      VALUES (?, ?, ?, ?, ?, 'pending', ?, NOW())
    `;
    db.query(
      sqlBooking,
      [req.user.id, car_id, vendorId, start_time, end_time, driver_required ? 1 : 0],
      (err2, result) => {
        if (err2) {
          console.error('DB error (insert booking):', err2);
          return res.status(500).json({ error: 'Database error (insert booking)' });
        }

        const bookingId = result.insertId;

        // ถ้าไม่ต้องการ driver → จบที่นี่
        if (!driver_required) {
          return res.json({
            message: 'Booking created without driver',
            booking_id: bookingId,
            driver_assigned: false,
          });
        }

        // หา driver (mock: เอาคนแรกในตาราง)
        const sqlDriver = `SELECT d.id FROM drivers d ORDER BY d.id ASC LIMIT 1`;
        db.query(sqlDriver, (err3, drivers) => {
          if (err3) {
            console.error('DB error (find driver):', err3);
            return res.status(500).json({ error: 'Database error (find driver)' });
          }

          if (drivers.length === 0) {
            console.warn('No drivers found for car_id', car_id);
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
            if (err4) {
              console.error('DB error (assign driver):', err4);
              return res.status(500).json({ error: 'Database error (assign driver)' });
            }

            return res.json({
              message: 'Booking created with driver',
              booking_id: bookingId,
              driver_assigned: true,
            });
          });
        });
      }
    );
  });
});

// ---------------- GET MY BOOKINGS ----------------
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
    if (err) {
      console.error('DB error (get my bookings):', err);
      return res.status(500).json({ error: 'Database error' });
    }
    res.json(rows);
  });
});

// ---------------- GET BOOKING DETAIL ----------------
// GET /api/bookings/:id
router.get('/:id', authenticate, (req, res) => {
  const { id } = req.params;
  const sql = `
    SELECT b.*, c.name AS car_name, v.name AS vendor_name
    FROM bookings b
    JOIN cars c ON b.car_id = c.id
    JOIN vendors v ON b.vendor_id = v.id
    WHERE b.id = ?
  `;
  db.query(sql, [id], (err, rows) => {
    if (err) {
      console.error('DB error (get booking detail):', err);
      return res.status(500).json({ error: 'Database error' });
    }
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Booking not found' });
    }
    res.json(rows[0]);
  });
});

module.exports = router;
