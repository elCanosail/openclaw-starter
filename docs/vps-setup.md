# Guía de Setup VPS — OpenClaw en producción

## Especificaciones recomendadas

| Componente | Mínimo | Recomendado |
|-----------|--------|-------------|
| CPU | 2 vCPU | 4 vCPU |
| RAM | 4 GB | 8 GB |
| Disco | 40 GB SSD | 80 GB SSD |
| SO | Ubuntu 24.04 LTS | Ubuntu 24.04 LTS |
| Coste | ~5€/mes | ~15€/mes |

## Paso 1: Provisioning

```bash
# SSH a tu VPS nueva
ssh root@TU_IP

# Actualizar sistema
apt-get update && apt-get upgrade -y

# Crear usuario de servicio (no ejecutar OpenClaw como root)
useradd -m -s /bin/bash -G sudo openclaw
echo "openclaw ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/openclaw

# Configurar hostname
hostnamectl set-hostname openclaw
```

## Paso 2: Seguridad básica

```bash
# Firewall
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Fail2ban
apt-get install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban

# SSH hardening
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd
```

## Paso 3: Node.js + OpenClaw

```bash
# Instalar Node.js 22
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

# Instalar OpenClaw
npm install -g openclaw pm2

# Verificar
openclaw --version
```

## Paso 4: Ollama

Ver guía separada: [ollama-setup.md](./ollama-setup.md)

Opción rápida (cloud):
1. Configura una instancia de Ollama Cloud
2. Añade la URL base a `openclaw.json`

Opción local:
```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull glm-5.1
ollama pull kimi-k2.6
```

## Paso 5: Configurar OpenClaw

```bash
# Copiar config
mkdir -p ~/.openclaw
cp config/openclaw.json ~/.openclaw/

# Editar con tus valores
vim ~/.openclaw/openclaw.json
# → Añadir TELEGRAM_BOT_TOKEN
# → Añadir ANTHROPIC_API_KEY (opcional)
# → Ajustar Ollama baseURL

# Configurar workspace
mkdir -p ~/openclaw-workspace
cp -r workspace/* ~/openclaw-workspace/

# Editar SOUL.md, USER.md, MEMORY.md con tus datos
vim ~/openclaw-workspace/SOUL.md
vim ~/openclaw-workspace/USER.md
```

## Paso 6: Gateway como servicio systemd

```bash
cat > /etc/systemd/system/openclaw-gateway.service << 'EOF'
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
User=openclaw
Environment=NODE_ENV=production
ExecStart=/usr/bin/openclaw gateway start --foreground
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable openclaw-gateway
systemctl start openclaw-gateway

# Verificar
systemctl status openclaw-gateway
curl http://localhost:18789/health
```

## Paso 7: Nginx reverse proxy (opcional)

Si quieres acceso web o webhooks:

```nginx
server {
    listen 443 ssl;
    server_name tu-dominio.com;

    ssl_certificate /etc/letsencrypt/live/tu-dominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tu-dominio.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:18789;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# Certbot
apt-get install -y certbot python3-certbot-nginx
certbot --nginx -d tu-dominio.com
```

## Paso 8: Backups

```bash
# Instalar rclone para GDrive (opcional)
curl https://rclone.org/install.sh | sudo bash
rclone config  # configurar "gdrive" remote

# Cron job de backup
crontab -e
# Añadir:
0 3 * * * /usr/local/bin/openclaw-backup >> /var/log/openclaw-backup.log 2>&1
```

## Paso 9: Verificación final

```bash
openclaw status        # Gateway running?
openclaw doctor       # Config OK?
curl localhost:18789/health  # Health check
pm2 list               # Procesos OK?
```

## Troubleshooting

### Gateway no arranca
```bash
openclaw gateway start --foreground  # ver errores en vivo
openclaw doctor --fix                 # reparar config
```

### Ollama no conecta
```bash
curl http://localhost:11434/api/tags   # verificar Ollama local
curl https://tu-ollama.example.com/api/tags  # verificar Ollama cloud
```

### Permisos
```bash
chown -R openclaw:openclaw ~/.openclaw/
chmod 600 ~/.openclaw/openclaw.json    # config tiene tokens
chmod 600 ~/.openclaw/workspace/TOOLS.md  # puede tener credenciales
```

### Memoria llena
```bash
du -sh ~/.openclaw/lcm.db              # verificar tamaño
sqlite3 ~/.openclaw/lcm.db "VACUUM;"   # optimizar
```