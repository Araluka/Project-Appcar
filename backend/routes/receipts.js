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

  // จำลองการชำระเงิน (สุ่มการชำระเงินที่สำเร็จหรือไม่สำเร็จ)
  const isPaymentSuccessful = Math.random() > 0.2; // 80% โอกาสในการชำระเงินสำเร็จ
  const transaction_id = `TXN-${Math.floor(Math.random() * 1000000)}`;

  if (isPaymentSuccessful) {
    // อัปเดตสถานะการชำระเงินในตาราง receipts
    const updatePaymentStatusSql = `
      UPDATE receipts 
      SET payment_status = 'paid', transaction_id = ? 
      WHERE booking_id = ?
    `;
    
    db.query(updatePaymentStatusSql, [transaction_id, booking_id], (err, result) => {
      if (err) {
        console.error("Error updating payment status in receipts:", err); // ดีบักข้อผิดพลาด
        return res.status(500).json({ message: 'เกิดข้อผิดพลาดในการอัปเดตสถานะการชำระเงินใน receipts' });
      }
      console.log("Payment status updated in receipts:", result); // ดีบักผลลัพธ์จากการอัปเดต

      // INSERT ข้อมูลลงตาราง payments
      const insertPaymentSql = `
        INSERT INTO payments (booking_id, transaction_id, payment_method, amount)
        VALUES (?, ?, ?, ?)
      `;
      db.query(insertPaymentSql, [booking_id, transaction_id, payment_method, total_amount], (err2, result2) => {
        if (err2) {
          console.error('Error inserting payment data into payments table:', err2); // ดีบักข้อผิดพลาด
          return res.status(500).json({ message: 'เกิดข้อผิดพลาดในการเพิ่มข้อมูลการชำระเงินใน payments' });
        }

        // เพิ่มข้อมูลลงในตาราง receipts (ใบเสร็จ)
        const insertReceiptSql = `
          INSERT INTO receipts (booking_id, transaction_id, total_amount, payment_status)
          VALUES (?, ?, ?, 'paid')
        `;
        db.query(insertReceiptSql, [booking_id, transaction_id, total_amount], (err3, result3) => {
          if (err3) {
            console.error('Error inserting data into receipts table:', err3); // ดีบักข้อผิดพลาด
            return res.status(500).json({ message: 'เกิดข้อผิดพลาดในการเพิ่มข้อมูลใบเสร็จใน receipts' });
          }

          console.log("Receipt inserted successfully:", result3); // ดีบักผลลัพธ์จากการ INSERT ใน receipts

          // อัปเดตสถานะการจองในตาราง bookings
          const updateBookingStatusSql = `
            UPDATE bookings
            SET status = 'confirmed' 
            WHERE id = ?
          `;
          
          db.query(updateBookingStatusSql, [booking_id], (err4, result4) => {
            if (err4) {
              console.error("Error updating booking status:", err4); // ดีบักข้อผิดพลาด
              return res.status(500).json({ message: 'เกิดข้อผิดพลาดในการอัปเดตสถานะการจองใน bookings' });
            }

            // ส่งการตอบกลับ
            res.json({
              message: 'ชำระเงินสำเร็จ',
              payment_status: 'paid',
              transaction_id: transaction_id,
              booking_status: 'confirmed'
            });
          });
        });
      });
    });
  } else {
    res.json({
      message: 'การชำระเงินล้มเหลว',
      payment_status: 'failed',
      transaction_id: null
    });
  }
});

module.exports = router;
