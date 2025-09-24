const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticate, authorize } = require('../middleware/authMiddleware');

// =======================================
// User: ดูแจ้งเตือนของตัวเอง
// =======================================
router.get('/my', authenticate, (req, res) => {
  const userId = req.user.id;
  const sql = `
    SELECT * FROM notifications
    WHERE user_id = ?
    ORDER BY created_at DESC
  `;
  db.query(sql, [userId], (err, results) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json(results);
  });
});

// =======================================
// User: mark แจ้งเตือนว่าอ่านแล้ว
// =======================================
router.patch('/:id/read', authenticate, (req, res) => {
  const notifId = req.params.id;
  const userId = req.user.id;

  const sql = `
    UPDATE notifications
    SET is_read = 1
    WHERE id = ? AND user_id = ?
  `;
  db.query(sql, [notifId, userId], (err, result) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (result.affectedRows === 0) return res.status(404).json({ message: 'ไม่พบการแจ้งเตือน' });
    res.json({ message: 'อัปเดตการแจ้งเตือนแล้ว' });
  });
});

// =======================================
// Admin: สร้างแจ้งเตือนให้ user
// =======================================
router.post('/', authenticate, authorize(['admin']), (req, res) => {
  const { user_id, title, message } = req.body;

  if (!user_id || !title || !message) {
    return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบ' });
  }

  const sql = `
    INSERT INTO notifications (user_id, title, message, is_read)
    VALUES (?, ?, ?, 0)
  `;
  db.query(sql, [user_id, title, message], (err, result) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.status(201).json({ message: 'สร้างการแจ้งเตือนสำเร็จ', notification_id: result.insertId });
  });
});

// =======================================
// Admin: ลบแจ้งเตือน
// =======================================
router.delete('/:id', authenticate, authorize(['admin']), (req, res) => {
  const notifId = req.params.id;
  const sql = 'DELETE FROM notifications WHERE id = ?';
  db.query(sql, [notifId], (err, result) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (result.affectedRows === 0) return res.status(404).json({ message: 'ไม่พบการแจ้งเตือนที่จะลบ' });
    res.json({ message: 'ลบการแจ้งเตือนสำเร็จ' });
  });
});

module.exports = router;
