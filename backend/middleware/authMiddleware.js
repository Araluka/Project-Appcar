const jwt = require('jsonwebtoken');
const JWT_SECRET = 'your_jwt_secret_key'; // ใช้ค่าเดียวกับ auth.js

const authenticate = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader) return res.status(401).json({ error: 'ไม่ได้ส่ง Token มา' });

  const token = authHeader.split(' ')[1]; // Format: Bearer <token>
  if (!token) return res.status(401).json({ error: 'Token format ไม่ถูกต้อง' });

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded; // เพิ่ม user เข้า req
    next();
  } catch (err) {
    return res.status(403).json({ error: 'Token ไม่ถูกต้อง' });
  }
};

module.exports = authenticate;
