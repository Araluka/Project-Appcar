const mysql = require('mysql2');

const connection = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: '', // ถ้ามีรหัสผ่านให้ใส่ที่นี่
  database: 'car_booking_app'
});

connection.connect((err) => {
  if (err) {
    console.error('❌ MySQL Connection Failed:', err);
    return;
  }
  console.log('✅ Connected to MySQL');
});

module.exports = connection;
