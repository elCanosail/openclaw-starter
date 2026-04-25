# Guía de Ollama — Modelos locales en VPS

## Opción A: Ollama Cloud (recomendado para VPS pequeños)

Si tu VPS tiene <8GB RAM, usa Ollama Cloud en lugar de modelos locales.

### Configuración en openclaw.json

```json
{
  "models": {
    "providers": {
      "ollama": {
        "baseUrl": "https://your-ollama-instance.example.com",
        "apiKey": "${OLLAMA_API_KEY}"
      }
    }
  }
}
```

### Modelos disponibles en Ollama Cloud

| Modelo | Alias | Uso recomendado |
|--------|-------|-----------------|
| GLM-5.1 | `glm` | Cotidiano, heartbeats, sub-agentes |
| Kimi K2.6 | `kimi` | Tareas complejas, código crítico |
| Qwen3.5 | `qwen35` | General purpose |
| DeepSeek V3.2 | `deepseek` | Razonamiento |
| Gemma 4 | `gemma4` | Tareas ligeras |

## Opción B: Ollama Local

### Instalación

```bash
# Script oficial
curl -fsSL https://ollama.com/install.sh | sh

# Iniciar servicio
sudo systemctl start ollama
sudo systemctl enable ollama
```

### Descargar modelos

```bash
# GLM-5.1 (principal, ~4GB)
ollama pull glm-5.1

# Kimi K2.6 (complejo, ~8GB)
ollama pull kimi-k2.6

# Qwen3.5 (balanceado, ~4GB)
ollama pull qwen3.5
```

### Verificar que funcionan

```bash
ollama list
ollama run glm-5.1 "Hola, ¿funcionas?"
```

### Configurar OpenClaw para Ollama local

```json
{
  "models": {
    "providers": {
      "ollama": {
        "baseUrl": "http://localhost:11434"
      }
    }
  }
}
```

## Comparativa: Cloud vs Local

| | Cloud | Local |
|--|-------|-------|
| **Coste** | Por token (~$0.001/1K) | Gratis (después de descarga) |
| **RAM** | 0MB en tu VPS | 4-16GB según modelo |
| **Latencia** | ~200-500ms | ~50-200ms |
| **Privacidad** | Datos salen de tu VPS | Todo en local |
| **Setup** | API key | Instalación + descarga |
| **Offline** | ❌ No | ✅ Sí |

## Recomendación

- **VPS CX22 (2 vCPU, 4GB):** Cloud obligatorio
- **VPS CX32 (4 vCPU, 8GB):** Cloud o local con modelos pequeños
- **VPS CPX31 (4 vCPU, 16GB):** Local con varios modelos
- **Máquina dedicada:** Local, todos los modelos
