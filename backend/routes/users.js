const express = require('express');
const router = express.Router();
const db = require('../db');
const { authenticate, authorize } = require('../middleware/authMiddleware');

// =======================================
// Admin only: Get all users
// =======================================
router.get('/', authenticate, authorize(['admin']), (req, res) => {
  const sql = 'SELECT id, name, email, phone, role, created_at, updated_at FROM users';
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    res.json(results);
  });
});

// =======================================
// Admin only: Get user by ID
// =======================================
router.get('/:id', authenticate, authorize(['admin']), (req, res) => {
  const userId = req.params.id;
  const sql = 'SELECT id, name, email, phone, role, created_at, updated_at FROM users WHERE id = ?';
  db.query(sql, [userId], (err, results) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (results.length === 0) return res.status(404).json({ error: 'ไม่พบผู้ใช้' });
    res.json(results[0]);
  });
});

// =======================================
// Admin only: Update user
// =======================================
router.put('/:id', authenticate, authorize(['admin']), (req, res) => {
  const userId = req.params.id;
  const { name, phone, role } = req.body;

  // ป้องกันการเปลี่ยนอีเมลหรือรหัสผ่านตรงนี้ (ถ้าจะมี route reset password ควรทำแยก)
  if (!name || !phone || !role) {
    return res.status(400).json({ error: 'กรุณากรอกข้อมูลให้ครบ' });
  }

  const sql = 'UPDATE users SET name = ?, phone = ?, role = ?, updated_at = NOW() WHERE id = ?';
  db.query(sql, [name, phone, role, userId], (err, result) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (result.affectedRows === 0) return res.status(404).json({ error: 'ไม่พบผู้ใช้' });
    res.json({ message: 'อัพเดทข้อมูลผู้ใช้สำเร็จ' });
  });
});

// =======================================
// Admin only: Delete user
// =======================================
router.delete('/:id', authenticate, authorize(['admin']), (req, res) => {
  const userId = req.params.id;

  const sql = 'DELETE FROM users WHERE id = ?';
  db.query(sql, [userId], (err, result) => {
    if (err) {
      if (err.code === 'ER_ROW_IS_REFERENCED_2') {
        return res.status(400).json({ error: 'ไม่สามารถลบผู้ใช้ เพราะมีการอ้างอิงจากตารางอื่น' });
      }
      return res.status(500).json({ error: 'Database error' });
    }
    if (result.affectedRows === 0) return res.status(404).json({ error: 'ไม่พบผู้ใช้' });

    res.json({ message: 'ลบผู้ใช้สำเร็จ' });
  });
});

module.exports = router;
