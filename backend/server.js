const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const { exec } = require('child_process');
const app = express();
const PORT = 3000;

// Middleware
app.use(express.json());
app.use(express.static('../'));

// Database setup
const db = new sqlite3.Database('voidattack.db');

// Login endpoint
app.post('/api/login', (req, res) => {
    const { username, password } = req.body;
    
    db.get('SELECT * FROM users WHERE username = ? AND password = ?', 
        [username, password], (err, row) => {
            if (err) {
                res.json({ success: false, error: 'Database error' });
            } else if (row) {
                res.json({ 
                    success: true, 
                    token: 'void-' + Date.now(),
                    user: row.username 
                });
            } else {
                res.json({ success: false, error: 'Invalid credentials' });
            }
        }
    );
});

// Launch attack endpoint
app.post('/api/attack', (req, res) => {
    const { target, method, intensity, duration, bots } = req.body;
    const attackId = 'attack-' + Date.now();
    
    // Log attack to database
    db.run('INSERT INTO attacks (target, method, status) VALUES (?, ?, ?)',
        [target, method, 'pending']);
    
    // Simulate attack (replace with real script)
    const logFile = `/tmp/${attackId}.log`;
    let command = '';
    
    if (method === 'slowloris') {
        command = `echo "Slowloris attack on ${target}" > ${logFile}`;
    } else if (method === 'http-flood') {
        command = `echo "HTTP Flood on ${target}" > ${logFile}`;
    } else {
        command = `echo "UDP Flood on ${target}" > ${logFile}`;
    }
    
    exec(command, (error) => {
        if (error) {
            res.json({ success: false, error: error.message });
        } else {
            res.json({ 
                success: true, 
                attackId,
                message: 'Attack launched successfully'
            });
        }
    });
});

// Get attack logs
app.get('/api/logs', (req, res) => {
    db.all('SELECT * FROM attacks ORDER BY timestamp DESC LIMIT 50', 
        (err, rows) => {
            if (err) {
                res.json({ logs: [] });
            } else {
                res.json({ logs: rows });
            }
        }
    );
});

// Get system stats
app.get('/api/stats', (req, res) => {
    const stats = {
        cpu: Math.floor(Math.random() * 30 + 30),
        ram: Math.floor(Math.random() * 40 + 40),
        attacks: Math.floor(Math.random() * 3 + 1),
        bots: Math.floor(Math.random() * 5 + 12),
        uptime: '99.8%'
    };
    res.json(stats);
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`✅ VoidAttack API running on port ${PORT}`);
    console.log(`📁 Static files served from ../`);
});
