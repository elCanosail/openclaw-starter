# OpenClaw Starter - Configuración de producción

> Repo público de configuración de referencia para OpenClaw. Basado en meses de uso en producción (VPS + Ollama Cloud + Anthropic fallback).
> 
> **Filosofía:** Menos, pero perfecto.

## ¿Qué es esto?

Una configuración de referencia para OpenClaw (https://docs.openclaw.ai) optimizada para:
- **VPS dedicada** (~5€/mes) con Ubuntu
- **Ollama local/cloud** como proveedor principal (sin coste por token)
- **Anthropic** como fallback para tareas críticas
- **Memoria dual** (LCM + QMD embeddings)
- **Telegram** como canal principal

## Estructura del repo

```
├── config/
│   └── openclaw.json           # Configuración principal
├── workspace/
│   ├── AGENTS.md               # Cómo se comporta el agente
│   ├── HEARTBEAT.md            # Tareas periódicas
│   ├── MEMORY.md               # Proyectos activos (tú lo mantienes)
│   ├── SOUL.md                 # Identidad del agente
│   ├── TOOLS.md                # Config técnica, credenciales
│   └── USER.md                 # Quién eres tú
├── scripts/
│   ├── install.sh              # Setup inicial en VPS
│   ├── backup.sh               # Backup diario (local + GDrive)
│   └── restart-gateway.sh      # Restart seguro del gateway
├── docs/
│   ├── vps-setup.md            # Guía completa de setup (35 pasos)
│   ├── ollama-setup.md         # Ollama cloud + modelos
│   ├── memory-guide.md         # LCM + QMD, cómo coexisten
│   └── cron-examples.md        # Ejemplos de cron + heartbeat
└── skills/
    └── (skills personalizadas)
```

## Quick start

1. Instalar OpenClaw: `npm install -g openclaw`
2. Copiar `config/openclaw.json` a `~/.openclaw/openclaw.json`
3. Configurar `workspace/` en tu directorio de trabajo
4. `openclaw gateway start`

## Lo más importante que hemos aprendido

### Modelos: calidad vs. coste

| Tarea | Modelo | Coste | Por qué |
|-------|--------|-------|---------|
| Cotidiano | GLM-5.1 (Ollama) | 0€ | Rápido, bueno para lo habitual |
| Complejo | Kimi K2.6 (Ollama) | 0€ | Mejor razonamiento profundo |
| Crítico / fallback | Claude Sonnet 4-6 | ~$0.005/1K tokens | Cuando Ollama falla |
| Council / análisis | Kimi K2.6 + GLM-5.1 | 0€ | Diversidad de opiniones |

### Memoria dual (LCM + QMD)

OpenClaw tiene **dos sistemas de memoria** que coexisten:

| Sistema | Qué hace | Herramientas |
|---------|----------|-------------|
| **LCM** | Conversaciones exactas sin pérdida | `lcm_grep`, `lcm_expand_query` |
| **QMD** | Búsqueda semántica por embeddings | `memory_search`, `memory_get` |

**Flujo:** `memory_search` primero (rápido, semántico) → `lcm_expand_query` si necesitas el contexto exacto.

Detalles completos: [docs/memory-guide.md](docs/memory-guide.md)

### Estructura de archivos workspace

```
workspace/
├── AGENTS.md        # Reglas de comportamiento (leído cada sesión)
├── HEARTBEAT.md     # Tareas periódicas (leído cada heartbeat)
├── MEMORY.md          # Proyectos activos, estado actual
├── SOUL.md          # Identidad, voz, límites del agente
├── TOOLS.md         # Credenciales, config técnica, notas
├── USER.md          # Quién eres tú, timezone, preferencias
├── memory/          # Archivos diarios auto-generados
│   ├── 2026-04-25.md
│   └── ...
└── docs/            # Documentación del proyecto
```

**Regla:** AGENTS.md + SOUL.md + USER.md se leen **cada sesión**. MEMORY.md solo en main session. HEARTBEAT.md en cada heartbeat poll.

### Sub-agentes

- **Modelo por defecto:** Kimi K2.6 vía Ollama (`ollama/kimi-k2.6:cloud`)
- **Uso:** Tareas largas, coding, research - lo que tarda >30s
- **Cambio proactivo:** El agente principal decide cuándo escalar
- **Monitorización:** `subagents list`, `sessions_list`

## Créditos

- Basado en [OpenClaw](https://github.com/openclaw/openclaw) - el framework
- Inspirado por [clawchief](https://github.com/snarktank/clawchief) — otro starter kit de referencia

---

*OpenClaw Starter Config*