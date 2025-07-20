const express = require('express');
const router = express.Router();
const db = require('../db');
const authenticate = require('../middleware/authMiddleware');

// ✅ GET /vendors/my → ร้านดูข้อมูลตัวเอง
router.get('/vendors/my', authenticate, (req, res) => {
  const userId = req.user.id;

  const sql = 'SELECT * FROM vendors WHERE user_id = ?';
  db.query(sql, [userId], (err, results) => {
    if (err) {
      console.error('❌ DB error:', err);
      return res.status(500).json({ error: 'Database error' });
    }

    if (results.length === 0) {
      return res.status(404).json({ message: 'ยังไม่มีข้อมูลร้านสำหรับผู้ใช้นี้' });
    }

    res.json({ vendor: results[0] });
  });
});

module.exports = router;
