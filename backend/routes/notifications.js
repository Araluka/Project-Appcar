const express = require('express');
const router = express.Router();
const db = require('../db');
const authenticate = require('../middleware/authMiddleware');

// ✅ ดูรายการแจ้งเตือนของผู้ใช้
router.get('/', authenticate, (req, res) => {
  const userId = req.user.id;

  const sql = 'SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC';
  db.query(sql, [userId], (err, results) => {
    if (err) {
      return res.status(500).json({ message: 'ไม่สามารถดึงการแจ้งเตือนได้', error: err });
    }

    res.json({ notifications: results });
  });
});
function createNotification(userId, title, message) {
  const insertNotificationSql = `
    INSERT INTO notifications (user_id, title, message)
    VALUES (?, ?, ?);
  `;
  
  db.query(insertNotificationSql, [userId, title, message], (err) => {
    if (err) {
      console.error('Error creating notification:', err);
    } else {
      console.log('Notification sent to user:', userId);
    }
  });
}

module.exports = router;
