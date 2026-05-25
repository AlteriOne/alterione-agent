# alterione-agent

> Core daemon of the [AlteriOne](https://alteri.one) AI agent framework.

**alterione-agent** is the central orchestrator of AlteriOne — a compiled, self-contained process that manages personas, coordinates LLM modules, handles memory, executes skills, and exposes an HTTP/WebSocket API for clients.

---

## Overview

```
alterione-agent
  │
  ├── Persona Manager     — loads and manages AI personas from config files
  ├── Pipeline Engine     — pre/post processes every request
  ├── Module Registry     — manages MCP modules (memory, LLM, skills)
  ├── Task Queue          — runs background and scheduled tasks
  ├── Cron Scheduler      — triggers periodic jobs per persona
  ├── Encrypted Storage   — secure local data store
  ├── Model Registry      — tracks downloaded GGUF models
  └── HTTP / WebSocket    — API for CLI and Flutter clients
```

---

## Requirements

- **OS**: Linux x64/arm64, macOS arm64/x64, Windows x64
- **No runtime required** — ships as a self-contained compiled binary
- At least one LLM module installed (e.g. `alterione-llm-ollama`)

---

## Installation

The recommended way is via the [AlteriOne installer](https://github.com/alterione/alterione-installer):

```bash
curl -fsSL https://get.alteri.one | sh
```

Or download the binary directly from [Releases](https://github.com/alterione/alterione-agent/releases):

```bash
# Linux x64
curl -fsSL https://github.com/alterione/alterione-agent/releases/latest/download/alterione-agent-linux-x64.tar.gz \
  | tar -xz -C ~/.alterione/
```

---

## Quick Start

```bash
# Start the agent (reads ~/.alterione/config/agent.yaml by default)
alterione-agent

# With custom config
alterione-agent --config /path/to/agent.yaml

# Start via CLI (recommended — includes supervisor)
alterione agent start
```

On first run, AlteriOne automatically:
- Creates `~/.alterione/` directory structure
- Generates an encrypted master key
- Copies default persona templates (`personal`, `work`)
- Generates default `agent.yaml` and `modules.yaml`

---

## Configuration

### agent.yaml

```yaml
agent:
  id: my-alterione
  version: 0.1.0

server:
  host: 127.0.0.1
  port: 8080
  ws_port: 8081
  auth:
    enabled: false
    token: ""

modules_config: ./config/modules.yaml
personas_dir:   ./personas/
data_dir:       ./data/
models_dir:     ./models/
logs_dir:       ./logs/

defaults:
  persona: personal
  llm_module: llm-ollama
  memory_module: memory-sqlite

llm:
  primary:
    module: llm-ollama
    model: llama3.1:8b
  pipeline:
    module: llm-ollama
    model: qwen2.5:1.5b

performance:
  compute_workers: 2
  max_concurrent_tasks: 4

watchdog:
  heartbeat_interval_sec: 10
  recovery_attempts: 3

recovery:
  recover_tasks_on_start: true
```

### modules.yaml

```yaml
modules:
  - id: memory-sqlite
    command: ./modules/alterione-memory-sqlite
    type: memory
    required: true
    autostart: true
    restart_policy: always

  - id: llm-ollama
    command: ./modules/alterione-llm-ollama
    type: llm
    required: true
    autostart: true
    config:
      base_url: http://localhost:11434

  - id: skill-web-search
    command: ./modules/alterione-skill-web
    type: skill
    required: false
    autostart: true
```

---

## Environment Variables

All settings can be overridden via environment variables. Priority: **CLI args > ENV > agent.yaml > defaults**.

| Variable | Description | Default |
|---|---|---|
| `ALTERIONE_CONFIG` | Path to agent.yaml | `~/.alterione/config/agent.yaml` |
| `ALTERIONE_HOST` | HTTP server host | `127.0.0.1` |
| `ALTERIONE_PORT` | HTTP server port | `8080` |
| `ALTERIONE_WS_PORT` | WebSocket port | `8081` |
| `ALTERIONE_DATA_DIR` | Data directory | `~/.alterione/data` |
| `ALTERIONE_MODELS_DIR` | Models directory | `~/.alterione/models` |
| `ALTERIONE_PERSONAS_DIR` | Personas directory | `~/.alterione/personas` |
| `ALTERIONE_LOG_LEVEL` | Log level (`trace`/`debug`/`info`/`warn`/`error`) | `info` |
| `ALTERIONE_LOG_FILE` | Log file path | stdout |
| `ALTERIONE_LOG_COLOR` | Colored output | `true` |
| `ALTERIONE_MASTER_KEY` | Master encryption key (required in Docker) | generated |
| `ALTERIONE_AUTH_ENABLED` | Enable API auth | `false` |
| `ALTERIONE_AUTH_TOKEN` | API bearer token | — |
| `ALTERIONE_COMPUTE_WORKERS` | Isolate compute pool size | `2` |
| `ALTERIONE_MAX_CONCURRENT_TASKS` | Max parallel tasks | `4` |
| `ALTERIONE_RECOVER_TASKS` | Recover interrupted tasks on start | `true` |
| `ALTERIONE_HEADLESS` | Disable interactive prompts | `false` |
| `ALTERIONE_RESTART_ON_CRASH` | Auto-restart on crash | `true` |
| `ALTERIONE_RESTART_MAX_ATTEMPTS` | Max crash restart attempts | `5` |
| `ALTERIONE_RESTART_DELAY_SEC` | Delay between restart attempts | `5` |

---

## Startup Phases

```
[BOOT] Bootstrap      — args, directories, logging
[BOOT] Lock           — prevent duplicate instances
[BOOT] First Run      — generate defaults (first start only)
[BOOT] Crypto         — isolates, master key
[BOOT] Storage        — encrypted DB, model registry
[BOOT] Modules        — spawn MCP processes, handshake
[BOOT] Personas       — load and validate persona configs
[BOOT] Tasks          — task store, cron scheduler, recovery
[BOOT] Server         — HTTP and WebSocket
[BOOT] Ready          — watchdog, signal handlers, PID file
```

---

## HTTP API

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/chat` | Send a message |
| `GET` | `/personas` | List personas |
| `POST` | `/personas` | Create persona |
| `POST` | `/personas/:id/activate` | Switch active persona |
| `DELETE` | `/personas/:id` | Delete persona |
| `GET` | `/modules` | List modules and status |
| `POST` | `/modules/:id/start` | Start a module |
| `POST` | `/modules/:id/stop` | Stop a module |
| `POST` | `/modules/:id/restart` | Restart a module |
| `GET` | `/models` | List installed models |
| `POST` | `/models/download` | Start model download |
| `GET` | `/models/download/:id` | Download progress (SSE) |
| `DELETE` | `/models/:id` | Remove a model |
| `GET` | `/tasks` | Current task pool |
| `POST` | `/tasks/:id/cancel` | Cancel a task |
| `GET` | `/cron` | List cron jobs |
| `POST` | `/cron/:id/run` | Run cron job immediately |
| `GET` | `/status` | System health |
| `POST` | `/agent/restart` | Trigger graceful restart |

WebSocket streaming at `ws://host:ws_port/chat/stream`.

---

## Personas

Each persona is a directory under `personas/`:

```
personas/
└── work/
    ├── persona.yaml       — settings, LLM config, memory, skills
    ├── system_prompt.md   — main system prompt
    ├── rules.md           — rules and constraints
    ├── style.md           — communication style
    ├── cron.yaml          — scheduled tasks for this persona
    └── knowledge/         — domain knowledge files
        └── context.md
```

---

## Docker

```bash
docker run -d \
  -p 8080:8080 -p 8081:8081 \
  -e ALTERIONE_HOST=0.0.0.0 \
  -e ALTERIONE_MASTER_KEY=your_base64_key \
  -e ALTERIONE_AUTH_TOKEN=your_secret \
  -v ./data:/alterione/data \
  -v ./personas:/alterione/personas \
  -v ./modules:/alterione/modules \
  alterione/agent:latest
```

```yaml
# docker-compose.yml
services:
  agent:
    image: alterione/agent:latest
    restart: unless-stopped
    ports:
      - "8080:8080"
      - "8081:8081"
    environment:
      ALTERIONE_HOST: 0.0.0.0
      ALTERIONE_MASTER_KEY: ${ALTERIONE_MASTER_KEY}
      ALTERIONE_AUTH_TOKEN: ${ALTERIONE_AUTH_TOKEN}
      ALTERIONE_LOG_COLOR: "false"
      ALTERIONE_HEADLESS: "true"
    volumes:
      - ./data:/alterione/data
      - ./models:/alterione/models
      - ./personas:/alterione/personas
      - ./config:/alterione/config
      - ./modules:/alterione/modules
```

---

## Directory Structure

```
~/.alterione/
├── bin/
│   └── alterione-agent
├── config/
│   ├── agent.yaml
│   ├── modules.yaml
│   └── cron.yaml
├── modules/
│   ├── alterione-memory-sqlite
│   ├── alterione-llm-ollama
│   └── alterione-skill-web
├── personas/
│   ├── personal/
│   └── work/
├── models/
│   ├── gguf/
│   └── metadata/
├── data/
│   ├── storage.db
│   ├── tasks.db
│   ├── agent.lock
│   └── agent.pid
└── logs/
    └── agent.log
```

---

## Exit Codes

| Code | Meaning | Auto-restart |
|---|---|---|
| `0` | Normal shutdown | No |
| `1` | Unexpected error | Yes (if policy allows) |
| `2` | Config error | No |
| `3` | Already running | No |
| `4` | Required module failed | No |
| `5` | No LLM module available | No |
| `6` | No personas found | No |
| `10` | Planned restart | Always |
| `11` | Restart after update | Always |

---

## Building from Source

```bash
git clone https://github.com/alterione/alterione-agent
cd alterione-agent
dart pub get
dart compile exe bin/main.dart -o alterione-agent
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Issues and PRs welcome.

This repository is part of the [AlteriOne](https://alteri.one) project.  
For architecture discussion, use [GitHub Discussions](https://github.com/alterione/alterione-agent/discussions).

---

## License

MIT — see [LICENSE](LICENSE)