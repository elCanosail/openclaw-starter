# Ejemplo de Cron Jobs para OpenClaw

## Configuración

```bash
crontab -e
```

## Jobs recomendados

### Backup diario
```cron
# Backup completo a las 3:00 AM
0 3 * * * /usr/local/bin/openclaw-backup >> /var/log/openclaw-backup.log 2>&1
```

### Health check del gateway
```cron
# Verificar gateway cada 15 minutos, restart si no responde
*/15 * * * * curl -sf http://localhost:18789/health > /dev/null || (systemctl restart openclaw-gateway && echo "$(date): Gateway restart" >> /var/log/openclaw-health.log)
```

### Rotación de logs
```cron
# Rotar logs semanales (comprimir los de hace 7+ días)
0 4 * * 0 find /var/log/openclaw* -mtime +7 -name "*.log" -exec gzip {} \; 2>/dev/null
0 4 * * 0 find /var/log/openclaw* -mtime +30 -name "*.gz" -delete 2>/dev/null
```

### Actualizaciones de seguridad
```cron
# Actualizaciones de seguridad automáticas (unattended-upgrades)
# Esto se configura una vez:
# dpkg-reconfigure -plow unattended-upgrades
```

## OpenClaw Cron Jobs (dentro de openclaw.json)

OpenClaw tiene su propio sistema de cron. Configúralos en `openclaw.json`:

```json
{
  "cron": {
    "entries": [
      {
        "name": "morning-briefing",
        "schedule": "0 8 * * 1-5",
        "task": "Revisa emails, calendario y clima. Usa la skill 'weather'. Resume lo importante.",
        "model": "ollama/glm-5.1:cloud"
      },
      {
        "name": "evening-wrap",
        "schedule": "0 21 * * 1-5",
        "task": "Resume el día: qué se hizo, qué queda pendiente. Actualiza MEMORY.md si es necesario.",
        "model": "ollama/glm-5.1:cloud"
      }
    ]
  }
}
```

### Cron vs Heartbeat

| | Cron | Heartbeat |
|--|------|-----------|
| **Timing** | Exacto (cron expression) | Aproximado (~30 min) |
| **Contexto** | Sin historial de sesión | Con historial reciente |
| **Modelo** | Puede ser diferente | Usa modelo de sesión |
| **Uso** | Tareas independientes | Verificaciones agrupadas |
| **Ejemplo** | "9:00 AM briefing" | "cada 30 min: email+cal+clima" |

**Tip:** Usa cron para lo que necesita timing exacto. Usa heartbeat para verificaciones que pueden agruparse.