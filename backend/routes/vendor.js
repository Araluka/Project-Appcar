// routes/vendor.js
const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticate, authorize } = require('../middleware/authMiddleware');

/**
 * helper: ทำ URL รูปให้เป็น absolute
 */
const toAbsUrl = (req, url) => {
  if (!url) return url;
  if (/^https?:\/\//i.test(url)) return url;
  return `${req.protocol}://${req.get('host')}${url.startsWith('/') ? '' : '/'}${url}`;
};

/**
 * ✅ GET /api/vendors/my
 * คืนโปรไฟล์ร้าน (vendor)
 */
router.get('/my', authenticate, authorize(['vendor']), (req, res) => {
  const userId = req.user.id;
  const sql = `
    SELECT v.id, v.name, v.address, v.location_lat, v.location_lng, v.created_at
    FROM vendors v
    WHERE v.user_id = ?
    LIMIT 1
  `;
  db.query(sql, [userId], (err, rows) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (rows.length === 0) return res.status(404).json({ error: 'Vendor not found' });
    res.json(rows[0]);
  });
});

/**
 * ✅ GET /api/vendors/my-bookings
 * รายการ booking ของร้าน
 */
router.get('/my-bookings', authenticate, authorize(['vendor']), (req, res) => {
  const userId = req.user.id;

  // 1) หา vendor_id ของ user
  const findVendorSql = `SELECT id FROM vendors WHERE user_id = ? LIMIT 1`;
  db.query(findVendorSql, [userId], (e1, vrows) => {
    if (e1) return res.status(500).json({ error: 'Database error (vendor lookup)' });
    if (vrows.length === 0) return res.status(404).json({ error: 'Vendor not found' });

    const vendorId = vrows[0].id;

    // 2) ดึง bookings พร้อม car + customer + ราคา
    const sql = `
      SELECT
        b.id AS booking_id,
        b.booking_date, b.start_time, b.end_time, b.status,
        b.driver_required, b.created_at,
        u.id AS customer_user_id, u.name AS customer_name, u.phone AS customer_phone,
        c.id AS car_id, c.name AS car_name, c.license_plate, c.image_url,
        c.price_per_day   -- ✅ เพิ่มราคามาด้วย
      FROM bookings b
      JOIN users u ON b.user_id = u.id
      JOIN cars c  ON b.car_id = c.id
      WHERE b.vendor_id = ?
      ORDER BY b.created_at DESC
    `;
    db.query(sql, [vendorId], (e2, rows) => {
      if (e2) return res.status(500).json({ error: 'Database error' });

      const mapped = rows.map(r => ({
        ...r,
        image_url: toAbsUrl(req, r.image_url),
      }));

      res.json(mapped);
    });
  });
});

/**
 * ✅ GET /api/vendors/booking/:id
 * รายละเอียด booking ของร้าน
 */
router.get('/booking/:id', authenticate, authorize(['vendor']), (req, res) => {
  const userId = req.user.id;
  const bookingId = req.params.id;

  // ตรวจ owner ร้าน
  const vendorSql = `SELECT id FROM vendors WHERE user_id = ? LIMIT 1`;
  db.query(vendorSql, [userId], (e1, vrows) => {
    if (e1) return res.status(500).json({ error: 'Database error (vendor lookup)' });
    if (vrows.length === 0) return res.status(404).json({ error: 'Vendor not found' });

    const vendorId = vrows[0].id;

    const detailSql = `
      SELECT
        b.id AS booking_id,
        b.booking_date, b.start_time, b.end_time, b.status,
        b.driver_required, b.created_at,
        u.id AS customer_user_id, u.name AS customer_name, u.phone AS customer_phone,
        c.id AS car_id, c.name AS car_name, c.license_plate, c.image_url,
        c.price_per_day   -- ✅ เพิ่มราคามาด้วย
      FROM bookings b
      JOIN users u ON b.user_id = u.id
      JOIN cars c  ON b.car_id = c.id
      WHERE b.id = ? AND b.vendor_id = ?
      LIMIT 1
    `;
    db.query(detailSql, [bookingId, vendorId], (e2, rows) => {
      if (e2) return res.status(500).json({ error: 'Database error' });
      if (rows.length === 0) return res.status(404).json({ error: 'Booking not found' });

      const row = rows[0];
      row.image_url = toAbsUrl(req, row.image_url);
      res.json(row);
    });
  });
});

module.exports = router;
