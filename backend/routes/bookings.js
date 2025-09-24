const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticate, authorize } = require('../middleware/authMiddleware');

// ฟังก์ชันสร้างการแจ้งเตือน
const createNotification = (userId, title, message) => {
  const sql = 'INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)';
  db.query(sql, [userId, title, message], (err) => {
    if (err) console.error('❌ ไม่สามารถสร้างการแจ้งเตือนได้', err);
  });
};

// ==================================================
// User: จองรถ
// ==================================================
router.post('/', authenticate, authorize(['customer']), (req, res) => {
  const userId = req.user.id;
  const { car_id, booking_date, start_time, end_time, driver_required = false } = req.body;

  // ตรวจความครบถ้วน
  if (!car_id || !booking_date || !start_time || !end_time) {
    return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบ' });
  }

  // ตรวจรูปแบบเวลา (start < end)
  const startTs = new Date(start_time).getTime();
  const endTs = new Date(end_time).getTime();
  if (isNaN(startTs) || isNaN(endTs) || startTs >= endTs) {
    return res.status(400).json({ message: 'ช่วงเวลาไม่ถูกต้อง (start_time ต้องน้อยกว่า end_time)' });
  }

  // 1) ดึง vendor จากรถก่อน
  const vendorSql = 'SELECT vendor_id, location_lat, location_lng FROM cars WHERE id = ?';
  db.query(vendorSql, [car_id], (err1, carRows) => {
    if (err1) return res.status(500).json({ message: 'เกิดข้อผิดพลาดในการตรวจสอบรถ', error: err1 });
    if (carRows.length === 0) return res.status(404).json({ message: 'ไม่พบบันทึกรถ' });

    const { vendor_id: vendorId, location_lat, location_lng } = carRows[0];

    // 2) กันจองซ้อนเวลา (ทับช่วงเวลาเดิมในวันเดียวกัน และสถานะ pending/confirmed)
    const overlapSql = `
      SELECT 1 FROM bookings
      WHERE car_id = ?
        AND booking_date = ?
        AND status IN ('pending','confirmed')
        AND NOT (
          end_time <= ? OR start_time >= ?
        )
      LIMIT 1
    `;
    db.query(overlapSql, [car_id, booking_date, start_time, end_time], (err2, ov) => {
      if (err2) return res.status(500).json({ message: 'เกิดข้อผิดพลาดในการตรวจสอบคิว', error: err2 });
      if (ov.length > 0) {
        return res.status(409).json({ message: 'ช่วงเวลานี้มีการจองแล้ว' });
      }

      // 3) สร้าง booking
      const insertSql = `
        INSERT INTO bookings
          (user_id, car_id, vendor_id, booking_date, start_time, end_time, driver_required, status, price)
        VALUES
          (?, ?, ?, ?, ?, ?, ?, 'pending', 0.00)
      `;
      db.query(insertSql, [userId, car_id, vendorId, booking_date, start_time, end_time, driver_required ? 1 : 0], (err3, result) => {
        if (err3) return res.status(500).json({ message: 'เกิดข้อผิดพลาดในการจอง', error: err3 });

        const bookingId = result.insertId;

        // แจ้งผลให้ client ก่อน (async งานอื่น ๆ ทำต่อ)
        res.status(201).json({ message: 'จองรถสำเร็จ', booking_id: bookingId });

        // แจ้งเตือน vendor เจ้าของรถ
        db.query('SELECT user_id FROM vendors WHERE id = ?', [vendorId], (e4, ownerRows) => {
          if (!e4 && ownerRows.length > 0) {
            createNotification(ownerRows[0].user_id, 'การจองใหม่', `ลูกค้า ${userId} จองรถวันที่ ${booking_date}`);
          }
        });

        // แจ้งเตือนลูกค้า
        if (driver_required) {
  // ถ้าไม่มีพิกัดรถ → ข้ามไป set no_driver_found ทันที
  if (location_lat == null || location_lng == null) {
    console.log('[booking] car has no lat/lng, mark no_driver_found');
    db.query('UPDATE bookings SET status="no_driver_found" WHERE id=?', [bookingId]);
    createNotification(userId, 'ยังไม่พบคนขับ', `รถไม่มีพิกัด จับคู่อัตโนมัติไม่ได้สำหรับ ${booking_date}`);
    return;
  }

       // ล็อกไว้ดูใน console
  console.log('[booking] try match driver near lat/lng:', location_lat, location_lng);

  const findDriverSql = `
    SELECT
      d.id AS driver_id,
      d.user_id AS driver_user_id,
      (6371 * acos(
        cos(radians(?)) * cos(radians(d.base_lat)) *
        cos(radians(d.base_lng) - radians(?)) +
        sin(radians(?)) * sin(radians(d.base_lat))
      )) AS distance_km
    FROM drivers d
    WHERE d.is_available = 1
      AND d.base_lat IS NOT NULL
      AND d.base_lng IS NOT NULL
    ORDER BY distance_km ASC
    LIMIT 3
  `;

          db.query(findDriverSql, [location_lat, location_lng, location_lat], (err5, candidates) => {
    if (err5) {
      console.log('❌ findDriver error:', err5);
      db.query('UPDATE bookings SET status="no_driver_found" WHERE id=?', [bookingId]);
      createNotification(userId, 'ยังไม่พบคนขับ', `ระบบยังไม่พบคนขับในรัศมีสำหรับวันที่ ${booking_date}`);
      return;
    }

    // กรองตามรัศมีจริง (กันกรณี acos คืน NULL)
    const withinRadius = (candidates || []).filter(r =>
      r.distance_km != null && r.distance_km <=  (Number.isFinite(r.service_radius_km) ? r.service_radius_km : 99999)
    );

    // ถ้าไม่มีใครในรัศมี ให้ลองเอา "ตัวที่ใกล้สุด" มาหนึ่งคนเป็น fallback (optional)
    const pick = (withinRadius.length > 0 ? withinRadius[0] : (candidates && candidates[0]));

    if (!pick) {
      console.log('ℹ️ no driver candidate');
      db.query('UPDATE bookings SET status="no_driver_found" WHERE id=?', [bookingId]);
      createNotification(userId, 'ยังไม่พบคนขับ', `ระบบยังไม่พบคนขับในรัศมีสำหรับวันที่ ${booking_date}`);
      return;
    }

    db.query('INSERT INTO driver_assignments (booking_id, driver_id) VALUES (?, ?)',
      [bookingId, pick.driver_id],
      (err6) => {
        if (err6) {
          console.log('❌ insert assignment error:', err6);
          db.query('UPDATE bookings SET status="no_driver_found" WHERE id=?', [bookingId]);
          return;
        }
        console.log(`[booking] assignment created: booking ${bookingId} -> driver ${pick.driver_id}`);
        createNotification(pick.driver_user_id, 'ได้รับงานใหม่', `คุณได้รับงานจากลูกค้า ${userId} วันที่ ${booking_date}`);
            });
          });
        }
      });
    });
  });
});

// ==================================================
// User: ดูประวัติการจองของตัวเอง
// ==================================================
router.get('/my', authenticate, authorize(['customer']), (req, res) => {
  const userId = req.user.id;
  const sql = `
    SELECT
      b.*,
      c.name AS car_name,
      c.license_plate,
      c.image_url
    FROM bookings b
    JOIN cars c ON b.car_id = c.id
    WHERE b.user_id = ?
    ORDER BY b.booking_date DESC, b.start_time DESC
  `;
  db.query(sql, [userId], (err, results) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json(results);
  });
});

// ==================================================
// User/Vendor: ยกเลิกการจอง
// ==================================================
router.patch('/:id/cancel', authenticate, (req, res) => {
  const actorUserId = req.user.id;
  const role = req.user.role;
  const bookingId = req.params.id;

  const sql = 'SELECT * FROM bookings WHERE id = ?';
  db.query(sql, [bookingId], (err, rows) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (rows.length === 0) return res.status(404).json({ message: 'ไม่พบการจอง' });

    const booking = rows[0];

    // เฉพาะสถานะที่ยกเลิกได้
    if (!['pending', 'confirmed', 'no_driver_found'].includes(booking.status)) {
      return res.status(400).json({ message: 'สถานะนี้ไม่สามารถยกเลิกได้' });
    }

    // สิทธิ์ยกเลิก:
    // - customer เจ้าของ booking
    // - vendor เจ้าของรถของ booking
    if (role === 'customer' && booking.user_id !== actorUserId) {
      return res.status(403).json({ message: 'ไม่สามารถยกเลิกการจองของผู้อื่นได้' });
    }

    const doCancelFlow = () => {
      const updateSql = 'UPDATE bookings SET status = "cancelled" WHERE id = ?';
      db.query(updateSql, [bookingId], (e1) => {
        if (e1) return res.status(500).json({ error: 'Database error' });

        // คืนสถานะรถ (กันลืม)
        db.query('UPDATE cars SET is_available = 1 WHERE id = ?', [booking.car_id]);

        // แจ้งเตือนอีกฝ่าย
        if (role === 'customer') {
          // แจ้ง vendor เจ้าของรถ
          db.query('SELECT user_id FROM vendors WHERE id = ?', [booking.vendor_id], (e2, ven) => {
            if (!e2 && ven.length > 0) {
              createNotification(ven[0].user_id, 'การจองถูกยกเลิก', `ลูกค้าได้ยกเลิกการจอง #${bookingId} วันที่ ${booking.booking_date}`);
            }
          });
          // ยืนยันกับลูกค้าเอง
          createNotification(actorUserId, 'ยกเลิกสำเร็จ', `คุณได้ยกเลิกการจอง #${bookingId}`);
        } else if (role === 'vendor') {
          // แจ้งลูกค้า
          createNotification(booking.user_id, 'การจองถูกยกเลิกโดยร้าน', `การจอง #${bookingId} ถูกยกเลิกโดยร้าน`);
        } else if (role === 'admin') {
          // แจ้งลูกค้า
          createNotification(booking.user_id, 'การจองถูกยกเลิกโดยผู้ดูแล', `การจอง #${bookingId} ถูกยกเลิกโดยผู้ดูแล`);
        }

        return res.json({ message: 'การจองถูกยกเลิกแล้ว' });
      });
    };

    if (role === 'vendor') {
      // ตรวจว่า vendor นี้เป็นเจ้าของรถจริง
      const vendorSql = 'SELECT v.user_id AS vendor_user_id FROM cars c JOIN vendors v ON c.vendor_id = v.id WHERE c.id = ?';
      db.query(vendorSql, [booking.car_id], (e0, owner) => {
        if (e0 || owner.length === 0) {
          return res.status(500).json({ message: 'ไม่พบข้อมูลร้านเจ้าของรถ' });
        }
        if (owner[0].vendor_user_id !== actorUserId) {
          return res.status(403).json({ message: 'คุณไม่มีสิทธิ์ยกเลิกการจองนี้' });
        }
        doCancelFlow();
      });
    } else if (role === 'admin' || role === 'customer') {
      doCancelFlow();
    } else {
      return res.status(403).json({ message: 'บทบาทนี้ไม่มีสิทธิ์ยกเลิกการจอง' });
    }
  });
});

// ==================================================
// Admin: ดูการจองทั้งหมด
// ==================================================
router.get('/all', authenticate, authorize(['admin']), (req, res) => {
  const sql = `
    SELECT
      b.*,
      u.name AS customer_name,
      c.name AS car_name,
      v.name AS vendor_name
    FROM bookings b
    JOIN users u ON b.user_id = u.id
    JOIN cars c ON b.car_id = c.id
    LEFT JOIN vendors v ON b.vendor_id = v.id
    ORDER BY b.created_at DESC
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json(results);
  });
});

module.exports = router;
