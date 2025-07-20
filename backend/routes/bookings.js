const express = require('express');
const router = express.Router();
const db = require('../db');
const authenticate = require('../middleware/authMiddleware');

// ฟังก์ชันสำหรับการสร้างการแจ้งเตือน
const createNotification = (userId, title, message) => {
  console.log(`สร้างการแจ้งเตือนให้ผู้ใช้ ${userId}: ${title} - ${message}`); // เพิ่ม log
  const sql = 'INSERT INTO notifications (user_id, title, message) VALUES (?, ?, ?)';
  db.query(sql, [userId, title, message], (err) => {
    if (err) console.error('ไม่สามารถสร้างการแจ้งเตือนได้', err);
  });
};

// ✅ จองรถ
router.post('/', authenticate, (req, res) => {
  const userId = req.user.id;  // userId ของลูกค้าที่จอง
  const { car_id, booking_date, start_time, end_time, driver_required = false } = req.body;

  if (!car_id || !booking_date || !start_time || !end_time) {
    return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบ' });
  }

  // ตรวจสอบว่ารถถูกจองในวันเดียวกันหรือยัง
  const checkSql = `
    SELECT * FROM bookings
    WHERE car_id = ? AND booking_date = ?
  `;

  db.query(checkSql, [car_id, booking_date], (err, existing) => {
    if (err) return res.status(500).json({ message: 'เกิดข้อผิดพลาดในการตรวจสอบรถว่าง', error: err });

    if (existing.length > 0) {
      return res.status(409).json({ message: 'รถคันนี้ถูกจองไปแล้วในวันดังกล่าว' });
    }

    // จองรถ
    const insertSql = `
      INSERT INTO bookings (user_id, car_id, booking_date, start_time, end_time, driver_required, status)
      VALUES (?, ?, ?, ?, ?, ?, 'pending')  -- กำหนดค่า default ของ status เป็น 'pending'
    `;

    db.query(insertSql, [userId, car_id, booking_date, start_time, end_time, driver_required], (err2, result) => {
      if (err2) return res.status(500).json({ message: 'เกิดข้อผิดพลาดในการจอง', error: err2 });

      const bookingId = result.insertId;

      res.status(201).json({
        message: 'จองรถสำเร็จ',
        booking_id: bookingId,
        driver_required
      });

      // ✅ หาร้านจาก car_id
      const getVendorSql = 'SELECT vendor_id FROM cars WHERE id = ?';
      db.query(getVendorSql, [car_id], (err3, vendorResult) => {
        if (err3 || vendorResult.length === 0) {
          console.log('❌ ไม่พบร้านที่เกี่ยวข้องกับรถคันนี้');
          return;
        }

        const vendorId = vendorResult[0].vendor_id; // ร้านที่มีการจอง

        // ดึง user_id ของเจ้าของร้านจาก vendor_id
        const getUserSql = 'SELECT user_id FROM vendors WHERE id = ?';
        db.query(getUserSql, [vendorId], (err4, userResult) => {
          if (err4 || userResult.length === 0) {
            console.log('❌ ไม่พบเจ้าของร้านที่เกี่ยวข้อง');
            return;
          }

          const ownerUserId = userResult[0].user_id;  // user_id ของเจ้าของร้าน
          
          // สร้างการแจ้งเตือนให้ร้าน
          createNotification(ownerUserId, 'การจองใหม่', `มีการจองรถใหม่จากลูกค้า ${userId} วันที่ ${booking_date}`);

          // ✅ แจ้งเตือนลูกค้าเมื่อจองสำเร็จ
          createNotification(userId, 'การจองสำเร็จ', `คุณได้ทำการจองรถสำเร็จวันที่ ${booking_date}`);

          // ✅ ถ้าระบุว่าต้องการคนขับ → หาคนขับใกล้ที่สุด
          if (driver_required) {
            const findDriverSql = `
              SELECT d.*, (
                6371 * acos(
                  cos(radians(c.location_lat)) * cos(radians(d.base_lat)) *
                  cos(radians(d.base_lng) - radians(c.location_lng)) +
                  sin(radians(c.location_lat)) * sin(radians(d.base_lat))
                )
              ) AS distance_km
              FROM drivers d
              JOIN cars c ON c.id = ?
              WHERE d.is_available = true
              HAVING distance_km <= d.service_radius_km
              ORDER BY distance_km ASC
              LIMIT 1
            `;

            db.query(findDriverSql, [car_id], (err5, driverRows) => {
              if (err5 || driverRows.length === 0) {
                console.log('❌ ไม่พบคนขับที่อยู่ในรัศมี หรือเกิดข้อผิดพลาด', err5);
                return;
              }

              const driver = driverRows[0];

              const assignSql = `
                INSERT INTO driver_assignments (booking_id, driver_id)
                VALUES (?, ?)
              `;
              db.query(assignSql, [bookingId, driver.id], (err6) => {
                if (err6) {
                  console.log('❌ บันทึกการจับคู่คนขับล้มเหลว', err6);
                } else {
                  console.log(`✅ จับคู่คนขับ ID ${driver.id} ให้กับ booking ${bookingId}`);
                  // ✅ แจ้งเตือนคนขับเมื่อได้รับการจับคู่
                  createNotification(driver.user_id, 'ได้รับงานใหม่', `คุณได้รับงานใหม่จากลูกค้า ${userId} วันที่ ${booking_date}`);
                }
              });
            });
          }
        });
      });
    });
  });
});




// ✅ ดูประวัติการจองของผู้ใช้
router.get('/', authenticate, (req, res) => {
  const userId = req.user.id;

  // ดึงข้อมูลการจองทั้งหมดของผู้ใช้
  const sql = `
    SELECT b.*, c.name AS car_name, c.license_plate, c.image_url
    FROM bookings b
    JOIN cars c ON b.car_id = c.id
    WHERE b.user_id = ?
    ORDER BY b.booking_date DESC
  `;

  db.query(sql, [userId], (err, results) => {
    if (err) {
      return res.status(500).json({ message: 'เกิดข้อผิดพลาดในการดึงข้อมูลการจอง', error: err });
    }

    if (results.length === 0) {
      return res.status(404).json({ message: 'ไม่พบประวัติการจอง' });
    }

    res.json({ bookings: results });
  });
});

// ✅ ยกเลิกการจอง
router.patch('/:id/cancel', authenticate, (req, res) => {
  const userId = req.user.id; // userId จาก token
  const bookingId = req.params.id;

  // ตรวจสอบว่าการจองนี้เป็นของผู้ใช้หรือลูกค้าหรือร้าน
  const checkSql = 'SELECT * FROM bookings WHERE id = ?';
  db.query(checkSql, [bookingId], (err, booking) => {
    if (err) return res.status(500).json({ message: 'เกิดข้อผิดพลาดในการตรวจสอบการจอง', error: err });

    if (booking.length === 0) {
      return res.status(404).json({ message: 'ไม่พบการจองที่ต้องการยกเลิก' });
    }

    const bookingStatus = booking[0].status;
    const bookingUserId = booking[0].user_id;
    const carId = booking[0].car_id;

    console.log('userId:', userId); // ตรวจสอบ userId ที่มาจาก token
    console.log('bookingUserId:', bookingUserId); // ตรวจสอบ bookingUserId
    console.log('Authenticated userId:', req.user.id); // ตรวจสอบ userId จาก token

    // ดึง vendor_id จากตาราง cars โดยใช้ car_id
    const getVendorSql = 'SELECT vendor_id FROM cars WHERE id = ?';
    db.query(getVendorSql, [carId], (err4, carResult) => {
      if (err4 || carResult.length === 0) {
        console.log("Error or no vendor found for car_id:", carId);
        return res.status(500).json({ message: 'ไม่พบร้านที่เกี่ยวข้องกับรถนี้' });
      }
      const vendorIdFromCar = carResult[0].vendor_id;
      console.log("vendorIdFromCar:", vendorIdFromCar); // ตรวจสอบ vendorId จากตาราง cars

      // เช็คว่า vendor_id ของร้านในตาราง users ตรงกับ vendor_id ที่ดึงมาได้จากตาราง cars หรือไม่
      const getVendorUserSql = 'SELECT user_id FROM vendors WHERE id = ?';
      db.query(getVendorUserSql, [vendorIdFromCar], (err5, vendorUserResult) => {
        if (err5 || vendorUserResult.length === 0) {
          console.log("Error or no vendor found for vendor_id:", vendorIdFromCar);
          return res.status(500).json({ message: 'ไม่พบร้านที่เกี่ยวข้องกับ vendor_id นี้' });
        }
        const vendorUserId = vendorUserResult[0].user_id;
        console.log("vendorUserId:", vendorUserId); // ตรวจสอบว่า vendor_id ของร้านเป็นของ user_id 5

        // ดีบักการเปรียบเทียบค่าต่างๆ
        console.log("Comparing:");
        console.log(`userId: ${userId}, vendorIdFromCar: ${vendorIdFromCar}`);
        console.log(`Type of userId: ${typeof userId}, Type of vendorIdFromCar: ${typeof vendorIdFromCar}`);

        // เปลี่ยนเป็นตัวเลขเพื่อให้การเปรียบเทียบทำงานได้ถูกต้อง
        if (Number(userId) === Number(vendorIdFromCar)) {
          console.log("The vendor ID matches the user ID.");
        } else {
          console.log("The vendor ID does not match the user ID.");
}


        // ตรวจสอบสิทธิ์การยกเลิก: ลูกค้าหรือร้าน
        if (userId === bookingUserId || userId === vendorUserId) {
          console.log("User has permission to cancel this booking.");
          // ตรวจสอบสถานะการจอง (ต้องเป็น "pending" หรือ "confirmed" เท่านั้น)
          if (bookingStatus !== 'pending' && bookingStatus !== 'confirmed') {
            return res.status(400).json({ message: 'ไม่สามารถยกเลิกการจองนี้ได้ เนื่องจากสถานะไม่ถูกต้อง' });
          }

          // อัปเดตสถานะการจองเป็น "cancelled"
          const updateBookingSql = 'UPDATE bookings SET status = "cancelled" WHERE id = ?';
          db.query(updateBookingSql, [bookingId], (err2) => {
            if (err2) return res.status(500).json({ message: 'ไม่สามารถยกเลิกการจองได้', error: err2 });

            // คืนสถานะรถให้กลับมาเป็น "ว่าง"
            const updateCarSql = 'UPDATE cars SET is_available = true WHERE id = ?';
            db.query(updateCarSql, [carId], (err3) => {
              if (err3) return res.status(500).json({ message: 'ไม่สามารถอัปเดตสถานะรถได้', error: err3 });

              // แจ้งเตือนร้าน (หากเป็นลูกค้ายกเลิก)
              if (userId === bookingUserId) {
                createNotification(vendorIdFromCar, 'การยกเลิกการจอง', `ลูกค้า ${userId} ได้ยกเลิกการจองรถ ID ${bookingId} วันที่ ${booking[0].booking_date}`);
              }

              // แจ้งเตือนลูกค้า (หากเป็นร้านยกเลิก)
              if (userId === vendorUserId) {
                createNotification(bookingUserId, 'การยกเลิกการจอง', `ร้าน ${userId} ได้ยกเลิกการจองรถ ID ${bookingId} วันที่ ${booking[0].booking_date}`);
              }

              res.json({ message: 'การจองถูกยกเลิกแล้ว' });
            });
          });
        } else {
          console.log("User does not have permission to cancel this booking.");
          return res.status(403).json({ message: 'คุณไม่มีสิทธิ์ยกเลิกการจองนี้' });
        }
      });
    });
  });
});





module.exports = router;
