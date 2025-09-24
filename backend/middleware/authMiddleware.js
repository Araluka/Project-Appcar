const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_key';

// ✅ ตรวจสอบ JWT
const authenticate = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader) return res.status(401).json({ error: 'ไม่ได้ส่ง Token มา' });

  const token = authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Token format ไม่ถูกต้อง' });

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded; // { id, role, email, name }
    next();
  } catch (err) {
    return res.status(403).json({ error: 'Token ไม่ถูกต้องหรือหมดอายุ' });
  }
};

// ✅ ตรวจสอบสิทธิ์ตาม role
const authorize = (roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'คุณไม่มีสิทธิ์เข้าถึง' });
    }
    next();
  };
};

module.exports = { authenticate, authorize };
