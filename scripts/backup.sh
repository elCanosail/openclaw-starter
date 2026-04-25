#!/bin/bash
#
# Backup diario de OpenClaw — Local + opcional GDrive
#

set -euo pipefail

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="openclaw-${DATE}"
LOCAL_DIR="${LOCAL_BACKUP_DIR:-/root/openclaw-backups}"
LOG="${LOG_FILE:-/var/log/openclaw-backup.log}"

tarball="${LOCAL_DIR}/${BACKUP_NAME}.tar.gz"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG"; }

log "=== Iniciando backup ==="

# Crear tarball
mkdir -p "$LOCAL_DIR"
tar czf "$tarball" \
    --exclude='*.log' \
    --exclude='node_modules' \
    --exclude='.git/objects' \
    --exclude='completions' \
    ~/.openclaw/openclaw.json \
    ~/.openclaw/workspace/ \
    ~/.openclaw/agents/ \
    ~/.openclaw/credentials/ \
    ~/.openclaw/cron/ \
    ~/.openclaw/lcm.db \
    2>> "$LOG"

# Backup a GDrive si rclone está configurado
if command -v rclone >/dev/null 2>&1 && rclone listremotes 2>/dev/null | grep -q "gdrive:"; then
    log "Subiendo a Google Drive..."
    rclone copy "$tarball" "gdrive:OpenClaw-Backups/$(hostname)/" 2>> "$LOG"
    log "✅ Backup en GDrive"
else
    log "⚠️ rclone/gdrive no configurado — backup solo local"
fi

# Limpiar backups antiguos (local: 7 días)
find "$LOCAL_DIR" -name "openclaw-*.tar.gz" -mtime +7 -delete 2>/dev/null || true

log "✅ Backup completado: $tarball"
