# Guía de LCM (Lossless Context Management)

## ¿Qué es LCM?

LCM es el plugin que permite a OpenClaw recordar conversaciones largas sin perder detalle. Sin LCM, el agente "olvida" lo que pasó hace 20 mensajes.

## Configuración

En `openclaw.json`:

```json
{
  "plugins": {
    "entries": {
      "lossless-claw": {
        "enabled": true,
        "config": {}
      }
    }
  },
  "memory": {
    "backend": "qmd",
    "qmd": {
      "sessions": {
        "enabled": true
      }
    }
  }
}
```

## Cómo funciona

1. **Conversación normal:** Todo lo que dices se guarda en la base de datos SQLite (`~/.openclaw/lcm.db`)
2. **Compactación automática:** Cuando hay muchos mensajes, LCM los resume en "summaries"
3. **Recuperación:** El agente puede buscar en summaries con `lcm_grep` o expandirlos con `lcm_expand_query`

## Uso del agente

### Buscar en el historial

```
lcm_grep "palabra clave"
lcm_grep "patrón regex" mode=regex
```

### Expandir un summary específico

```
lcm_expand_query query="proyecto X" prompt="¿Qué decisiones se tomaron?"
```

### Ver metadatos de un summary

```
lcm_describe id="sum_xxxxxxxx"
```

## Flujo recomendado

1. **Si necesitas recordar algo:** primero `lcm_grep`
2. **Si el summary promete detalles:** `lcm_expand_query` con prompt enfocado
3. **Nunca** afirmes hechos específicos de memórias comprimidas sin expandir primero

## Troubleshooting

### "No encuentro nada en LCM"
- Verifica que `lossless-claw` está instalado: `openclaw plugins list`
- Verifica que `lcm.db` existe: `ls -la ~/.openclaw/lcm.db`
- El historial se empieza a guardar desde que instalaste el plugin

### "LCM es muy lento"
- La base de datos SQLite puede crecer. Si pasa de 500MB, considera:
  - `vacuum` en la DB: `sqlite3 ~/.openclaw/lcm.db "VACUUM;"`
  - O simplemente borrar historial antiguo (se regenera)

## Tamaño típico

| Uso | Tamaño LCM |
|-----|-----------|
| 1 mes | ~2-5 MB |
| 3 meses | ~10-20 MB |
| 6 meses | ~30-50 MB |

LCM es muy eficiente. No necesitas limpiarla frecuentemente.
