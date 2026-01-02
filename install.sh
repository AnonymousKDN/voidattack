#!/bin/bash

echo "⚡ VOIDATTACK v1.0 INSTALLER ⚡"
echo "================================"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
  echo "❌ Please run as root: sudo bash install.sh"
  exit 1
fi

echo "[1/6] Updating system..."
apt update && apt upgrade -y

echo "[2/6] Installing dependencies..."
apt install -y git nodejs npm nginx python3 python3-pip curl wget

echo "[3/6] Setting up web directory..."
mkdir -p /var/www/voidattack
cp -r ./* /var/www/voidattack/
chown -R www-data:www-data /var/www/voidattack

echo "[4/6] Configuring Nginx..."
cat > /etc/nginx/sites-available/voidattack << 'EOF'
server {
    listen 80;
    server_name _;
    root /var/www/voidattack;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
EOF

ln -sf /etc/nginx/sites-available/voidattack /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

echo "[5/6] Restarting services..."
nginx -t && systemctl restart nginx
systemctl enable nginx

echo "[6/6] Setting up Node.js backend..."
cd /var/www/voidattack/backend
npm init -y
npm install express sqlite3

# Create database
node -e "
const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('voidattack.db');
db.run('CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, username TEXT, password TEXT)');
db.run('INSERT OR IGNORE INTO users (username, password) VALUES (\"admin\", \"voidattack123\")');
db.run('CREATE TABLE IF NOT EXISTS attacks (id INTEGER PRIMARY KEY, target TEXT, method TEXT, status TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)');
db.close();
"

# Create systemd service
cat > /etc/systemd/system/voidattack-api.service << 'EOF'
[Unit]
Description=VoidAttack API Service
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/voidattack/backend
ExecStart=/usr/bin/node server.js
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start voidattack-api
systemctl enable voidattack-api

# Get server IP
IP=$(curl -s ifconfig.me)

echo "✅ INSTALLATION COMPLETE!"
echo "================================"
echo "🌐 Dashboard URL: http://$IP"
echo "👤 Username: admin"
echo "🔑 Password: voidattack123"
echo "================================"
echo "📁 Files: /var/www/voidattack"
echo "📝 Logs: /var/log/nginx/error.log"
echo "⚙️ Backend: systemctl status voidattack-api"
echo "================================"