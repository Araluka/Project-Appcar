const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticate, authorize } = require('../middleware/authMiddleware');

// helper: สร้างแจ้งเตือน
const notify = (userId, title, message) => {
  const sql = 'INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)';
  db.query(sql, [userId, title, message], (err) => {
    if (err) console.error('notify error:', err);
  });
};

// -----------------------------
// ดูงานที่ระบบส่งมาให้ (ของคนขับที่ล็อกอิน) - pending เท่านั้น
// GET /api/driver-assignments/my-jobs
// -----------------------------
router.get('/my-jobs', authenticate, authorize(['driver']), (req, res) => {
  const driverUserId = req.user.id;

  const sql = `
    SELECT
      da.id AS assignment_id,
      da.is_accepted,
      da.responded_at,
      b.id AS booking_id,
      b.booking_date, b.start_time, b.end_time, b.status AS booking_status,
      b.driver_required,
      c.id AS car_id, c.name AS car_name, c.license_plate,
      u.id AS customer_id, u.name AS customer_name, u.phone AS customer_phone
    FROM driver_assignments da
    JOIN drivers d ON da.driver_id = d.id
    JOIN bookings b ON da.booking_id = b.id
    JOIN cars c ON b.car_id = c.id
    JOIN users u ON b.user_id = u.id
    WHERE d.user_id = ?
      AND da.is_accepted = 0
    ORDER BY b.booking_date DESC, b.start_time DESC
  `;
  db.query(sql, [driverUserId], (err, rows) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json(rows);
  });
});

// -----------------------------
// กด "รับงาน"
// PATCH /api/driver-assignments/:id/accept
// -----------------------------
router.patch('/:assignmentId/accept', authenticate, authorize(['driver']), (req, res) => {
  const assignmentId = req.params.assignmentId;
  const driverUserId = req.user.id;

  // 1) ตรวจว่า assignment นี้เป็นของ driver คนที่ล็อกอิน
  const ownSql = `
    SELECT da.id, da.driver_id, b.id AS booking_id, b.user_id AS customer_user_id,
           b.vendor_id, b.created_at, b.status
    FROM driver_assignments da
    JOIN drivers d ON da.driver_id = d.id
    JOIN bookings b ON da.booking_id = b.id
    WHERE da.id = ? AND d.user_id = ?
      AND da.is_accepted = 0
    LIMIT 1
  `;
  db.query(ownSql, [assignmentId, driverUserId], (err, rows) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (rows.length === 0) return res.status(404).json({ message: 'ไม่พบงานหรือสถานะไม่พร้อมรับ' });

    const { booking_id, driver_id, customer_user_id, vendor_id } = rows[0];

    // 2) ตรวจลิมิตเวลา 12 ชม. นับจากตอนสร้าง booking (optional)
    const windowSql = `SELECT TIMESTAMPDIFF(HOUR, created_at, NOW()) AS hrs FROM bookings WHERE id = ?`;
    db.query(windowSql, [booking_id], (e2, r2) => {
      if (!e2 && r2.length > 0 && r2[0].hrs > 12) {
        return res.status(400).json({ message: 'หมดเวลายืนยันงาน (เกิน 12 ชม.)' });
      }

      // 3) ยืนยัน assignment นี้
      const acceptSql = `
        UPDATE driver_assignments
        SET is_accepted = 1, responded_at = NOW()
        WHERE id = ? AND is_accepted = 0
      `;
      db.query(acceptSql, [assignmentId], (e3, r3) => {
        if (e3) return res.status(500).json({ error: 'Database error' });
        if (r3.affectedRows === 0) {
          return res.status(409).json({ message: 'งานนี้ถูกตอบไปแล้ว' });
        }

        // 4) ปิด assignment อื่นๆ ของ booking เดียวกัน (ให้เป็น -1 = ปฏิเสธโดยระบบ)
        const closeOthers = `
          UPDATE driver_assignments
          SET is_accepted = -1, responded_at = NOW()
          WHERE booking_id = ? AND id <> ? AND is_accepted = 0
        `;
        db.query(closeOthers, [booking_id, assignmentId]);

        // 5) อัปเดตสถานะ booking เป็น confirmed + (ถ้ามีคอลัมน์ driver_id ให้เซ็ตด้วย)
        const setBooking = `
          UPDATE bookings
          SET status = 'confirmed', driver_id = ?
          WHERE id = ?
        `;
        db.query(setBooking, [driver_id, booking_id], (e4) => {
          if (e4) {
            // กรณีไม่มีคอลัมน์ driver_id ในตาราง ก็อัปเดตเฉพาะ status
            db.query(`UPDATE bookings SET status='confirmed' WHERE id=?`, [booking_id]);
          }
        });

        // 6) ตั้งสถานะคนขับไม่ว่าง
        db.query(`UPDATE drivers SET is_available = 0 WHERE id = ?`, [driver_id]);

        // 7) แจ้งเตือนลูกค้าและร้าน
        notify(customer_user_id, 'ยืนยันคนขับแล้ว', `การจอง #${booking_id} ได้รับการยืนยันคนขับแล้ว`);
        if (vendor_id) {
          db.query('SELECT user_id FROM vendors WHERE id=?', [vendor_id], (e5, vr) => {
            if (!e5 && vr.length > 0) {
              notify(vr[0].user_id, 'งานถูกยืนยันโดยคนขับ', `การจอง #${booking_id} ถูกยืนยันคนขับแล้ว`);
            }
          });
        }

        return res.json({ message: 'ยืนยันงานสำเร็จ' });
      });
    });
  });
});

// -----------------------------
// กด "ปฏิเสธงาน"
// PATCH /api/driver-assignments/:id/reject
// -----------------------------
router.patch('/:assignmentId/reject', authenticate, authorize(['driver']), (req, res) => {
  const assignmentId = req.params.assignmentId;
  const driverUserId = req.user.id;

  // ตรวจความเป็นเจ้าของ assignment
  const ownSql = `
    SELECT da.id, da.driver_id, da.booking_id, b.user_id AS customer_user_id
    FROM driver_assignments da
    JOIN drivers d ON da.driver_id = d.id
    JOIN bookings b ON da.booking_id = b.id
    WHERE da.id = ? AND d.user_id = ? AND da.is_accepted = 0
    LIMIT 1
  `;
  db.query(ownSql, [assignmentId, driverUserId], (err, rows) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (rows.length === 0) return res.status(404).json({ message: 'ไม่พบงานหรือสถานะไม่พร้อมปฏิเสธ' });

    const { booking_id, customer_user_id } = rows[0];

    const rejSql = `
      UPDATE driver_assignments
      SET is_accepted = -1, responded_at = NOW()
      WHERE id = ? AND is_accepted = 0
    `;
    db.query(rejSql, [assignmentId], (e2, r2) => {
      if (e2) return res.status(500).json({ error: 'Database error' });
      if (r2.affectedRows === 0) return res.status(409).json({ message: 'งานนี้ถูกตอบไปแล้ว' });

      // แจ้งลูกค้าว่ายังไม่พบคนขับ (เฉพาะกรณีไม่มี assignment pending อื่น ๆ)
      const leftSql = `
        SELECT 1 FROM driver_assignments WHERE booking_id=? AND is_accepted=0 LIMIT 1
      `;
      db.query(leftSql, [booking_id], (e3, left) => {
        if (!e3 && left.length === 0) {
          // ยังไม่มีคนขับที่รับ → ให้สถานะ booking = no_driver_found ไว้ก่อน
          db.query(`UPDATE bookings SET status='no_driver_found' WHERE id=? AND status <> 'cancelled'`, [booking_id]);
          notify(customer_user_id, 'ยังไม่พบคนขับ', `งาน #${booking_id} ยังไม่มีคนขับรับงานในตอนนี้`);
        }
      });

      return res.json({ message: 'ปฏิเสธงานเรียบร้อย' });
    });
  });
});

// -----------------------------
// ประวัติการให้บริการของคนขับ (งานที่รับแล้ว)
// GET /api/driver-assignments/my-history
// -----------------------------
router.get('/my-history', authenticate, authorize(['driver']), (req, res) => {
  const driverUserId = req.user.id;
  const sql = `
    SELECT
      da.id AS assignment_id,
      b.id AS booking_id, b.booking_date, b.start_time, b.end_time, b.status,
      c.name AS car_name, c.license_plate,
      u.name AS customer_name
    FROM driver_assignments da
    JOIN drivers d ON da.driver_id = d.id
    JOIN bookings b ON da.booking_id = b.id
    JOIN cars c ON b.car_id = c.id
    JOIN users u ON b.user_id = u.id
    WHERE d.user_id = ? AND da.is_accepted = 1
    ORDER BY b.booking_date DESC, b.start_time DESC
  `;
  db.query(sql, [driverUserId], (err, rows) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json(rows);
  });
});

module.exports = router;
