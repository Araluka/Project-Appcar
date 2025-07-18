const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const db = require('./db');

const authRoutes = require('./routes/auth');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(bodyParser.json());


// ✅ ใช้งานเส้นทาง auth
app.use('/api', authRoutes);

app.get('/', (req, res) => {
  res.send('🚗 Car Booking API is running!');
});

app.listen(PORT, () => {
  console.log(`✅ Server is running on http://localhost:${PORT}`);
});
