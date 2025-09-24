const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticate, authorize } = require('../middleware/authMiddleware');

// =======================================
// User: ชำระเงินสำหรับการจอง
// =======================================
// POST /api/payments
router.post('/', authenticate, authorize(['customer']), (req, res) => {
  const { booking_id, transaction_id, payment_method, amount } = req.body;
  if (!booking_id || !transaction_id || !payment_method || !amount) {
    return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบ' });
  }

  // 1) ตรวจว่า booking เป็นของลูกค้าคนนี้จริง
  const ownSql = 'SELECT id, user_id, driver_required, price FROM bookings WHERE id = ?';
  db.query(ownSql, [booking_id], (ownErr, ownRows) => {
    if (ownErr) return res.status(500).json({ error: 'Database error' });
    if (ownRows.length === 0) return res.status(404).json({ message: 'ไม่พบการจอง' });
    if (ownRows[0].user_id !== req.user.id) {
      return res.status(403).json({ error: 'คุณไม่มีสิทธิ์ชำระเงินสำหรับการจองนี้' });
    }

    // 2) กันชำระซ้ำ: ถ้ามีใบเสร็จแล้ว / หรือมี payment=paid แล้ว → ห้าม
    const chkSql = `
      SELECT 1 FROM receipts WHERE booking_id = ?
      UNION
      SELECT 1 FROM payments WHERE booking_id = ? AND payment_status = 'paid' LIMIT 1
    `;
    db.query(chkSql, [booking_id, booking_id], (chkErr, chkRows) => {
      if (chkErr) return res.status(500).json({ error: 'Database error' });
      if (chkRows.length > 0) {
        return res.status(409).json({ message: 'รายการนี้ชำระเงินเรียบร้อยแล้ว' });
      }

      // 3) insert payment เป็น paid
      const paySql = `
        INSERT INTO payments (booking_id, transaction_id, payment_method, amount, payment_status)
        VALUES (?, ?, ?, ?, 'paid')
      `;
      db.query(paySql, [booking_id, transaction_id, payment_method, amount], (payErr, payResult) => {
        if (payErr) return res.status(500).json({ error: 'Database error', details: payErr });

        // 4) อัปเดตสถานะ booking
        const updateBooking = `
          UPDATE bookings SET status = IF(driver_required=1, 'pending', 'confirmed')
          WHERE id = ?
        `;
        db.query(updateBooking, [booking_id]);

        // 5) ออกใบเสร็จ (กันซ้ำด้วย unique key)
        const receiptSql = `
          INSERT INTO receipts (booking_id, transaction_id, total_amount, payment_status)
          VALUES (?, ?, ?, 'paid')
          ON DUPLICATE KEY UPDATE transaction_id = VALUES(transaction_id), total_amount = VALUES(total_amount)
        `;
        db.query(receiptSql, [booking_id, transaction_id, amount], (rcErr) => {
          if (rcErr) return res.status(500).json({ error: 'สร้างใบเสร็จไม่สำเร็จ', details: rcErr });

          return res.status(201).json({
            message: 'ชำระเงินสำเร็จ และออกใบเสร็จแล้ว',
            payment_id: payResult.insertId
          });
        });
      });
    });
  });
});


// =======================================
// User: ดูการชำระเงินของตัวเอง
// =======================================
router.get('/my', authenticate, authorize(['customer']), (req, res) => {
  const userId = req.user.id;
  const sql = `
    SELECT p.*, b.booking_date, b.start_time, b.end_time, c.name AS car_name
    FROM payments p
    JOIN bookings b ON p.booking_id = b.id
    JOIN cars c ON b.car_id = c.id
    WHERE b.user_id = ?
    ORDER BY p.created_at DESC
  `;
  db.query(sql, [userId], (err, results) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json(results);
  });
});

// =======================================
// Admin: ดูการชำระเงินทั้งหมด
// =======================================
router.get('/all', authenticate, authorize(['admin']), (req, res) => {
  const sql = `
    SELECT p.*, b.id AS booking_id, u.name AS customer_name, v.name AS vendor_name
    FROM payments p
    JOIN bookings b ON p.booking_id = b.id
    JOIN users u ON b.user_id = u.id
    JOIN vendors v ON b.vendor_id = v.id
    ORDER BY p.created_at DESC
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json(results);
  });
});

module.exports = router;
