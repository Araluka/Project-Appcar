const express = require('express');
const router = express.Router();
const db = require('../db');

// Mock API สำหรับชำระเงิน
router.post('/pay', (req, res) => {
  const { payment_method, total_amount, booking_id } = req.body; // รับข้อมูลการชำระเงินจากลูกค้า

  // ตรวจสอบวิธีการชำระเงิน
  const paymentMethods = ['promptpay', 'qr', 'credit_card'];
  if (!paymentMethods.includes(payment_method)) {
    return res.status(400).json({ message: 'วิธีการชำระเงินไม่ถูกต้อง' });
  }

  // 1. ตรวจสอบสถานะการชำระเงินก่อนการชำระ
  const checkPaymentStatusSql = `
    SELECT payment_status FROM payments WHERE booking_id = ?
  `;
  
  db.query(checkPaymentStatusSql, [booking_id], (err, result) => {
    if (err) {
      console.error("Error checking payment status:", err);
      return res.status(500).json({ message: 'เกิดข้อผิดพลาดในการตรวจสอบสถานะการชำระเงิน' });
    }

    // ถ้าจองนี้ชำระแล้ว
    if (result.length > 0 && result[0].payment_status === 'paid') {
      return res.status(400).json({ message: 'การชำระเงินสำหรับการจองนี้เสร็จสิ้นแล้ว' });
    }

    // 2. จำลองการชำระเงิน (สุ่มการชำระเงินที่สำเร็จหรือไม่สำเร็จ)
    const isPaymentSuccessful = Math.random() > 0.2; // 80% โอกาสในการชำระเงินสำเร็จ
    const transaction_id = `TXN-${Math.floor(Math.random() * 1000000)}`;

    if (isPaymentSuccessful) {
      // 3. ใส่ข้อมูลการชำระเงิน (เริ่มต้นสถานะเป็น 'pending')
      const insertPaymentSql = `
        INSERT INTO payments (booking_id, transaction_id, payment_method, amount, payment_status)
        VALUES (?, ?, ?, ?, 'pending')
      `;
      
      db.query(insertPaymentSql, [booking_id, transaction_id, payment_method, total_amount], (err, result) => {
        if (err) {
          console.error('Error inserting payment data into payments table:', err);
          return res.status(500).json({ message: 'เกิดข้อผิดพลาดในการเพิ่มข้อมูลการชำระเงิน' });
        }

        // 4. อัปเดตสถานะการชำระเงินเป็น 'completed' (หลังจากชำระเงินเสร็จ)
        const updatePaymentStatusSql = `
          UPDATE payments
          SET payment_status = 'paid'
          WHERE transaction_id = ?
        `;
        db.query(updatePaymentStatusSql, [transaction_id], (err2, result2) => {
          if (err2) {
            console.error('Error updating payment status to paid:', err2);
            return res.status(500).json({ message: 'เกิดข้อผิดพลาดในการอัปเดตสถานะการชำระเงิน' });
          }

          // 5. สร้างใบเสร็จในตาราง receipts หลังการชำระเงินเสร็จสิ้น
          const insertReceiptSql = `
            INSERT INTO receipts (booking_id, transaction_id, total_amount, payment_status)
            VALUES (?, ?, ?, 'paid')
          `;
          db.query(insertReceiptSql, [booking_id, transaction_id, total_amount], (err3, result3) => {
            if (err3) {
              console.error('Error inserting data into receipts table:', err3);
              return res.status(500).json({ message: 'เกิดข้อผิดพลาดในการเพิ่มข้อมูลใบเสร็จ' });
            }

            // 6. อัปเดตสถานะการจองในตาราง bookings
            const updateBookingStatusSql = `
              UPDATE bookings
              SET status = 'confirmed' 
              WHERE id = ?
            `;
            
            db.query(updateBookingStatusSql, [booking_id], (err4, result4) => {
              if (err4) {
                console.error("Error updating booking status:", err4);
                return res.status(500).json({ message: 'เกิดข้อผิดพลาดในการอัปเดตสถานะการจอง' });
              }

              // ส่งการตอบกลับ
              res.json({
                message: 'ชำระเงินสำเร็จและใบเสร็จได้รับการสร้างแล้ว',
                payment_status: 'paid',
                transaction_id: transaction_id,
                booking_status: 'confirmed'
              });
            });
          });
        });
      });
    } else {
      // หากการชำระเงินล้มเหลว
      const insertPaymentFailedSql = `
        INSERT INTO payments (booking_id, transaction_id, payment_method, amount, payment_status)
        VALUES (?, ?, ?, ?, 'failed')
      `;
      
      db.query(insertPaymentFailedSql, [booking_id, transaction_id, payment_method, total_amount], (err, result) => {
        if (err) {
          console.error('Error inserting failed payment data into payments table:', err);
          return res.status(500).json({ message: 'เกิดข้อผิดพลาดในการเพิ่มข้อมูลการชำระเงินล้มเหลว' });
        }

        res.json({
          message: 'การชำระเงินล้มเหลว',
          payment_status: 'failed',
          transaction_id: transaction_id
        });
      });
    }
  });
});

module.exports = router;
