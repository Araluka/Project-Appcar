const express = require('express');
const router = express.Router();
const cron = require('node-cron');
const db = require('../db');
const authenticate = require('../middleware/authMiddleware');


// ✅ ดูรายการงานที่จับคู่ไว้ (ยังไม่ตอบรับ)
router.get('/assignments', authenticate, (req, res) => {
  const userId = req.user.id;

  // ค้นหา driver_id จาก user_id
  const driverSql = 'SELECT id FROM drivers WHERE user_id = ?';
  db.query(driverSql, [userId], (err, result) => {
    if (err || result.length === 0) {
      return res.status(404).json({ error: 'ไม่พบข้อมูลคนขับ' });
    }

    const driverId = result[0].id;

    // ดูงานที่ยังไม่ตอบรับ
    const assignmentsSql = `
      SELECT da.id as assignment_id, b.*, c.name as car_name
      FROM driver_assignments da
      JOIN bookings b ON da.booking_id = b.id
      JOIN cars c ON b.car_id = c.id
      WHERE da.driver_id = ? AND da.is_accepted IS NULL
    `;

    db.query(assignmentsSql, [driverId], (err2, rows) => {
      if (err2) return res.status(500).json({ error: 'ดึงข้อมูลล้มเหลว' });
      res.json({ assignments: rows });
    });
  });
});
// กำหนด cron job ที่จะทำงานทุก 5 นาที
cron.schedule('*/5 * * * *', () => {
  console.log("Running cron job to check for unaccepted driver assignments...");

  // ค้นหาการจองที่ยังไม่ได้ตอบรับในช่วง 12 ชั่วโมงที่ผ่านมา
  const checkSql = `
    SELECT da.id, da.booking_id, da.driver_id, da.responded_at, b.start_time
    FROM driver_assignments da
    JOIN bookings b ON da.booking_id = b.id
    WHERE da.is_accepted IS NULL 
    AND da.responded_at IS NULL 
    AND b.start_time < NOW() - INTERVAL 12 HOUR;
  `;

  db.query(checkSql, (err, results) => {
    if (err) {
      console.error('Error checking unaccepted driver assignments:', err);
      return;
    }

    if (results.length > 0) {
      console.log(`${results.length} unaccepted driver assignments found.`);

      results.forEach((assignment) => {
        const { id, booking_id, driver_id } = assignment;

        // หาคนขับที่ว่างในระบบ
        const findDriverSql = `
          SELECT id 
          FROM drivers 
          WHERE is_available = 1 
          AND id != ? 
          ORDER BY RAND() 
          LIMIT 1;
        `;

        db.query(findDriverSql, [driver_id], (err2, driverResults) => {
          if (err2) {
            console.error('Error finding available driver:', err2);
            return;
          }

          if (driverResults.length > 0) {
            const newDriverId = driverResults[0].id;
            
            // อัปเดตการจับคู่คนขับ
            const updateDriverAssignmentSql = `
              UPDATE driver_assignments 
              SET driver_id = ?, responded_at = NOW(), is_accepted = 1 
              WHERE id = ?;
            `;
            
            db.query(updateDriverAssignmentSql, [newDriverId, id], (err3) => {
              if (err3) {
                console.error('Error updating driver assignment:', err3);
                return;
              }

              // แจ้งเตือนลูกค้าและคนขับใหม่
              console.log(`Driver assignment updated for booking ID: ${booking_id}, new driver ID: ${newDriverId}`);

              // ส่งการแจ้งเตือนให้ลูกค้าและคนขับใหม่ (ฟังก์ชันการแจ้งเตือนที่คุณจะสร้าง)
              createNotification(booking_id, 'การจองใหม่', `คนขับใหม่ได้รับการจับคู่กับการจองของคุณ`);
              createNotification(newDriverId, 'งานใหม่', `คุณได้รับงานใหม่สำหรับการจอง ID ${booking_id}`);
            });
          } else {
            console.log('No available driver found for assignment ID:', assignment.id);
          }
        });
      });
    } else {
      console.log('No unaccepted driver assignments found.');
    }
  });
});

// ✅ ตอบรับหรือปฏิเสธงาน
router.patch('/assignments/:id', authenticate, (req, res) => {
  const assignmentId = req.params.id;
  const { accept } = req.body; // true = ตอบรับ, false = ปฏิเสธ
  const userId = req.user.id;

  const driverSql = 'SELECT id FROM drivers WHERE user_id = ?';
  db.query(driverSql, [userId], (err, result) => {
    if (err || result.length === 0) {
      return res.status(404).json({ error: 'ไม่พบข้อมูลคนขับ' });
    }

    const driverId = result[0].id;

    // ตรวจสอบว่า assignment นี้เป็นของคนขับคนนี้
    const checkSql = 'SELECT * FROM driver_assignments WHERE id = ? AND driver_id = ?';
    db.query(checkSql, [assignmentId, driverId], (err2, rows) => {
      if (err2 || rows.length === 0) {
        return res.status(404).json({ error: 'ไม่พบงานที่เกี่ยวข้อง' });
      }

      // อัปเดตสถานะการตอบรับ
      const updateSql = `
        UPDATE driver_assignments
        SET is_accepted = ?, responded_at = NOW()
        WHERE id = ?
      `;

      db.query(updateSql, [accept ? 1 : 0, assignmentId], (err3) => {
        if (err3) return res.status(500).json({ error: 'ไม่สามารถอัปเดตสถานะได้' });

        // ถ้ายอมรับ → เปลี่ยน booking เป็น confirmed
        if (accept) {
          const bookingId = rows[0].booking_id;
          const updateBooking = `
            UPDATE bookings
            SET status = 'confirmed'
            WHERE id = ?
          `;
          db.query(updateBooking, [bookingId], () => {
            return res.json({ message: 'ตอบรับงานเรียบร้อยแล้ว' });
          });
        } else {
          return res.json({ message: 'ปฏิเสธงานแล้ว' });
        }
      });
    });
  });
});

module.exports = router;
