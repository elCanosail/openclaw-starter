# HEARTBEAT.md — Prioridades actuales

## Prioridad: [Tu proyecto estrella]
**Tarea más importante ahora**

- Acción clave 1
- Acción clave 2

## Health check de bots (cada heartbeat)

1. `pm2 logs [bot-name] --nostream --lines 50` — buscar errores, equity anómala, crashes
2. Si hay errores: diagnosticar, fixear, restart, commit. No esperar a tu humano.
3. Si el bot está parado (stopped/errored): investigar y levantar.

## Pendientes

- [ ] Item 1
- [ ] Item 2

## REGLAS

- **Modelo sub-agentes:** `ollama/kimi-k2.6:cloud` (Kimi K2.6) — mejor relación calidad/precio para sub-agentes
- **Modelo para tareas complejas:** `ollama/kimi-k2.6:cloud` (Kimi K2.6) — mejor contexto y razonamiento profundo
- **Anthropic disponibles:** Sonnet 4-6 (`anthropic/claude-sonnet-4-6`) y Opus 4-6 (`anthropic/claude-opus-4-6`) — uso manual o cuando Ollama falle
- Cambio proactivo: si detecto que la tarea requiere más capacidad, propongo cambiar modelo ANTES de ejecutarla:
  - Análisis profundo, decisión estratégica → Kimi K2.6 (Ollama)
  - Código crítico → Kimi K2.6 (Ollama)
  - Council / pressure-test → Kimi K2.6 + GLM-5.1 como peer
  - Research largo, docs extensos → Kimi K2.6 (Ollama)
  - Frontend diseño impecable → Kimi K2.6 (Ollama)
  - Sub-agentes, summaries, heartbeats → GLM-5.1 (se queda)
- Después de cada tarea: build + restart + screenshot de verificación
- Si algo rompe el build: revertir con git checkout y documentar
- Commit después de cada tarea exitosa
