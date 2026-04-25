#!/bin/bash
#
# OpenClaw Starter — Setup script para VPS Ubuntu 24.04
# Basado en la config de producción de Elcano (Hetzner CX22)
#

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[SETUP]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ─── 1. Verificar sistema ──────────────────────────────────
log "Verificando sistema..."
if [ "$(id -u)" != "0" ]; then error "Ejecutar como root: sudo bash install.sh"; fi
if ! grep -q "Ubuntu 24" /etc/os-release 2>/dev/null; then warn "No es Ubuntu 24.04 — continúa bajo tu responsabilidad"; fi

# ─── 2. Variables ──────────────────────────────────────────
HOSTNAME="${HOSTNAME:-openclaw-vps}"
USERNAME="${USERNAME:-admin}"
WORKSPACE_DIR="${WORKSPACE_DIR:-/home/$USERNAME/openclaw-workspace}"
NODE_VERSION="22"

log "Configurando para: host=$HOSTNAME, user=$USERNAME"

# ─── 3. Actualizar sistema ────────────────────────────────
log "Actualizando paquetes..."
apt-get update && apt-get upgrade -y
apt-get install -y \
    curl git vim ufw fail2ban \
    build-essential ca-certificates gnupg \
    htop jq python3 python3-pip \
    nginx certbot python3-certbot-nginx

# ─── 4. Crear usuario ──────────────────────────────────────
log "Creando usuario $USERNAME..."
if ! id "$USERNAME" > /dev/null 2>&1; then
    useradd -m -s /bin/bash -G sudo "$USERNAME"
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/"$USERNAME"
fi

# ─── 5. Instalar Node.js ─────────────────────────────────
log "Instalando Node.js $NODE_VERSION..."
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
apt-get install -y nodejs
npm install -g pm2

# ─── 6. Instalar OpenClaw ────────────────────────────────
log "Instalando OpenClaw..."
npm install -g openclaw
openclaw doctor --fix >/devdev/null 2>&1 || true

# ─── 7. Configurar firewall ──────────────────────────────
log "Configurando UFW..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# ─── 8. Crear directorio workspace ───────────────────────
log "Creando workspace en $WORKSPACE_DIR..."
mkdir -p "$WORKSPACE_DIR"
chown -R "$USERNAME:$USERNAME" "$WORKSPACE_DIR"

# ─── 9. Copiar archivos de config ────────────────────────
log "Copiando archivos de configuración..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copiar config de OpenClaw
if [ -f "$SCRIPT_DIR/../config/openclaw.json" ]; then
    mkdir -p /home/"$USERNAME"/.openclaw
    cp "$SCRIPT_DIR/../config/openclaw.json" /home/"$USERNAME"/.openclaw/
    chown -R "$USERNAME:$USERNAME" /home/"$USERNAME"/.openclaw
fi

# Copiar workspace templates
if [ -d "$SCRIPT_DIR/../workspace" ]; then
    cp -r "$SCRIPT_DIR/../workspace"/* "$WORKSPACE_DIR"/
    chown -R "$USERNAME:$USERNAME" "$WORKSPACE_DIR"
fi

# ─── 10. Configurar backups ─────────────────────────────
log "Configurando sistema de backup..."
mkdir -p /root/logs /root/openclaw-backups
if [ -f "$SCRIPT_DIR/backup.sh" ]; then
    cp "$SCRIPT_DIR/backup.sh" /usr/local/bin/openclaw-backup
    chmod +x /usr/local/bin/openclaw-backup
    # Cron job para backup diario
    (crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/openclaw-backup >> /var/log/openclaw-backup.log 2>&1") | crontab -
fi

# ─── 11. Configurar hostname ─────────────────────────────
log "Configurando hostname..."
hostnamectl set-hostname "$HOSTNAME"
echo "127.0.1.1 $HOSTNAME" >> /etc/hosts

# ─── 12. Mensaje final ──────────────────────────────────
cat <<EOF

${GREEN}╔════════════════════════════════════════════════════════════╗
║           OpenClaw Starter — Setup completado                ║
╚════════════════════════════════════════════════════════════╝${NC}

Próximos pasos:

1. ${YELLOW}Configurar Ollama${NC}:
   - Instala Ollama: https://ollama.com/download
   - O configura Ollama Cloud con tu API key

2. ${YELLOW}Configurar Telegram${NC}:
   - Crea un bot con @BotFather
   - Edita ~/.openclaw/openclaw.json con tu token

3. ${YELLOW}Configurar Anthropic${NC} (opcional, fallback):
   - Obtén API key en https://console.anthropic.com
   - Añade ANTHROPIC_API_KEY a ~/.openclaw/openclaw.json

4. ${YELLOW}Iniciar${NC}:
   openclaw gateway start

5. ${YELLOW}Verificar${NC}:
   openclaw status

Workspace: $WORKSPACE_DIR
Config:    /home/$USERNAME/.openclaw/openclaw.json
Backups:   /root/openclaw-backups/ (diario 3AM)
Logs:      /var/log/openclaw-backup.log

${GREEN}¡Listo!${NC}

EOF
