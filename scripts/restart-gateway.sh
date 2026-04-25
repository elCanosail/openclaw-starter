#!/bin/bash
#
# Restart seguro del gateway OpenClaw
#

set -euo pipefail

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

log "Verificando estado del gateway..."

if openclaw status 2>/dev/null | grep -q "running"; then
    log "Gateway activo. Reiniciando..."
    openclaw gateway restart
    sleep 2
    if openclaw status 2>/dev/null | grep -q "running"; then
        log "✅ Gateway reiniciado correctamente"
    else
        log "❌ Gateway no responde tras restart"
        exit 1
    fi
else
    log "Gateway parado. Iniciando..."
    openclaw gateway start
    sleep 2
    if openclaw status 2>/dev/null | grep -q "running"; then
        log "✅ Gateway iniciado correctamente"
    else
        log "❌ Gateway no pudo iniciar"
        exit 1
    fi
fi
