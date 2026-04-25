# Sistema de Memoria — OpenClaw

OpenClaw tiene **dos sistemas de memoria complementarios**. No son competidores — cada uno resuelve un problema distinto.

## Los dos sistemas

| | LCM (Lossless Context Management) | QMD (Active Memory + Embeddings) |
|--|-----------------------------------|----------------------------------|
| **Qué hace** | Guarda conversaciones exactas, sin pérdida | Búsqueda semántica por similitud |
| **Para qué** | "¿Qué se dijo exactamente sobre X en marzo?" | "¿Dónde hablé de algo parecido a X?" |
| **Tipo** | SQLite (compresión sin pérdida) | Embeddings vectoriales |
| **Tamaño típico** | ~600MB para 2 meses | Depende de chunks |
| **Herramientas** | `lcm_grep`, `lcm_expand`, `lcm_expand_query` | `memory_search`, `memory_get` |
| **Cuándo usar** | Recuperar contexto exacto de conversaciones | Buscar por concepto/tema |

## Configuración

```json
{
  "memory": {
    "backend": "qmd",
    "qmd": {
      "sessions": {
        "enabled": true
      }
    }
  },
  "plugins": {
    "entries": {
      "lcm": {
        "enabled": true,
        "mode": "lossless",
        "config": {
          "dbPath": "~/.openclaw/lcm.db",
          "maxSummarize": 10000,
          "autoSummarize": true
        }
      }
    }
  }
}
```

Ambos se activan en paralelo. No hay conflicto.

## Flujo de uso diario

### Buscar por concepto → `memory_search`

```bash
# "¿Dónde hablé de Docker?"
memory_search("Docker networking")
```

Devuelve resultados por similitud semántica. Rápido, no necesita contexto exacto.

### Recuperar conversación exacta → `lcm_grep` + `lcm_expand_query`

```bash
# "¿Qué decidimos sobre la migración de base de datos en marzo?"
lcm_grep("migración base de datos")
lcm_expand_query(
  query="migración base de datos",
  prompt="Qué estrategia de migración se decidió?"
)
```

LCM expande el DAG de resúmenes para reconstruir el contexto exacto. Más lento pero sin pérdida.

### Patrón recomendado

1. **`memory_search`** primero — rápido, buena para la mayoría de consultas
2. Si necesitas detalles exactos → **`lcm_grep`** para localizar la conversación
3. Luego **`lcm_expand_query`** para recuperar el contexto completo

## Estructura de archivos de memoria

```
~/.openclaw/
├── lcm.db                          # LCM: conversaciones comprimidas
└── workspace/
    ├── MEMORY.md                   # Proyectos activos (inyectado cada sesión)
    ├── memory/
    │   ├── 2026-04-25.md          # Notas diarias
    │   └── heartbeat-state.json   # Estado de verificaciones
    └── TOOLS.md                    # Config técnica (también inyectado)
```

### Qué se lee cada sesión

| Archivo | Main session | Sub-agentes |
|---------|-------------|-------------|
| SOUL.md | ✅ | ✅ |
| USER.md | ✅ | ✅ |
| AGENTS.md | ✅ | ✅ |
| MEMORY.md | ✅ | ❌ |
| TOOLS.md | ✅ | ❌ |
| HEARTBEAT.md | Heartbeat only | ❌ |

## Mantenimiento

### LCM DB

```bash
# Ver tamaño
du -sh ~/.openclaw/lcm.db

# Ver estadísticas
sqlite3 ~/.openclaw/lcm.db "SELECT COUNT(*) FROM summaries; SELECT COUNT(*) FROM messages;"

# Optimizar (VACUUM)
sqlite3 ~/.openclaw/lcm.db "VACUUM;"

# Si crece demasiado (>1GB), considerar purge de conversaciones antiguas
```

### MEMORY.md

- Auditoría semanal: verificar que no hay duplicados, datos obsoletos
- Mantener conciso — se inyecta en cada sesión main
- Mover detalles a `memory/YYYY-MM-DD.md`, mantener solo lo activo

### Archivos diarios

- `memory/YYYY-MM-DD.md` — notas del día
- LCM gestiona el historial detallado automáticamente
- No necesitas archivar manualmente — LCM ya lo hace