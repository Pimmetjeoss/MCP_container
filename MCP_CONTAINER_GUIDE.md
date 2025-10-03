# Uitgebreide Gids: MCP Servers in Docker Containers

## Inhoudsopgave
1. [Overzicht](#overzicht)
2. [Waarom MCP Servers in Containers?](#waarom-mcp-servers-in-containers)
3. [Vereisten](#vereisten)
4. [Basis Stappenplan](#basis-stappenplan)
5. [Gedetailleerde Stappen](#gedetailleerde-stappen)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)
8. [Voorbeelden](#voorbeelden)

---

## Overzicht

Een MCP (Model Context Protocol) server is een service die tools en resources beschikbaar stelt aan AI-applicaties zoals Claude Desktop. Door MCP servers in Docker containers te draaien, krijg je een geïsoleerde, reproduceerbare en gemakkelijk te distribueren omgeving.

---

## Waarom MCP Servers in Containers?

### Voordelen:
- ✅ **Isolatie**: Dependencies conflicteren niet met je lokale systeem
- ✅ **Reproduceerbaarheid**: Dezelfde omgeving op elk systeem
- ✅ **Portabiliteit**: Makkelijk delen en deployen
- ✅ **Versiebeheer**: Meerdere versies naast elkaar draaien
- ✅ **Security**: Beveiligde sandbox omgeving
- ✅ **Cleanup**: Verwijder containers zonder rommel achter te laten

---

## Vereisten

### Software:
- **Docker Desktop** (Windows/Mac) of **Docker Engine** (Linux)
  - Download: https://www.docker.com/products/docker-desktop
- **Claude Desktop** (voor het testen van MCP servers)
  - Download: https://claude.ai/download
- **Code editor** (VS Code, Notepad++, etc.)

### Basiskennis:
- Basis command-line gebruik
- Begrijpen van JSON formaat
- (Optioneel) Python basics voor het schrijven van custom servers

---

## Basis Stappenplan

```
1. Maak een projectfolder
2. Schrijf je MCP server code
3. Maak een requirements/dependencies bestand
4. Schrijf een Dockerfile
5. Bouw de Docker image
6. Test de container
7. Configureer Claude Desktop
8. Test de integratie
```

---

## Gedetailleerde Stappen

### Stap 1: Projectstructuur Opzetten

Maak een nieuwe folder voor je MCP server project:

```bash
mkdir mijn-mcp-server
cd mijn-mcp-server
```

Aanbevolen structuur:
```
mijn-mcp-server/
├── Dockerfile
├── requirements.txt (Python) of package.json (Node.js)
├── server.py of server.js
├── .dockerignore (optioneel)
└── README.md (optioneel)
```

---

### Stap 2: MCP Server Code Schrijven

#### Python Voorbeeld:

**server.py**
```python
import asyncio
from mcp.server.models import InitializationOptions
from mcp.server import NotificationOptions, Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

server = Server("mijn-server")

@server.list_tools()
async def handle_list_tools() -> list[Tool]:
    return [
        Tool(
            name="mijn-tool",
            description="Beschrijving van wat de tool doet",
            inputSchema={
                "type": "object",
                "properties": {
                    "input": {
                        "type": "string",
                        "description": "Input beschrijving"
                    }
                },
                "required": ["input"]
            }
        )
    ]

@server.call_tool()
async def handle_call_tool(name: str, arguments: dict) -> list[TextContent]:
    if name == "mijn-tool":
        input_value = arguments.get("input")
        result = f"Verwerkt: {input_value}"
        return [TextContent(type="text", text=result)]

    raise ValueError(f"Onbekende tool: {name}")

async def main():
    async with stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="mijn-server",
                server_version="1.0.0",
                capabilities=server.get_capabilities(
                    notification_options=NotificationOptions(),
                    experimental_capabilities={},
                )
            )
        )

if __name__ == "__main__":
    asyncio.run(main())
```

#### Node.js Voorbeeld:

**server.js**
```javascript
#!/usr/bin/env node
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

const server = new Server(
  {
    name: "mijn-server",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

server.setRequestHandler("tools/list", async () => ({
  tools: [
    {
      name: "mijn-tool",
      description: "Beschrijving van wat de tool doet",
      inputSchema: {
        type: "object",
        properties: {
          input: {
            type: "string",
            description: "Input beschrijving",
          },
        },
        required: ["input"],
      },
    },
  ],
}));

server.setRequestHandler("tools/call", async (request) => {
  const { name, arguments: args } = request.params;

  if (name === "mijn-tool") {
    const result = `Verwerkt: ${args.input}`;
    return {
      content: [
        {
          type: "text",
          text: result,
        },
      ],
    };
  }

  throw new Error(`Onbekende tool: ${name}`);
});

const transport = new StdioServerTransport();
await server.connect(transport);
```

---

### Stap 3: Dependencies Definiëren

#### Python (requirements.txt):
```
mcp>=1.0.0
httpx
pydantic
```

#### Node.js (package.json):
```json
{
  "name": "mijn-mcp-server",
  "version": "1.0.0",
  "type": "module",
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0"
  }
}
```

---

### Stap 4: Dockerfile Schrijven

#### Python Dockerfile:

```dockerfile
FROM python:3.11-slim

# Metadata
LABEL maintainer="jouw.email@example.com"
LABEL description="MCP Server in Docker"

# Installeer systeem dependencies (indien nodig)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Installeer uv voor snellere Python package installatie
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# Werkdirectory instellen
WORKDIR /app

# Dependencies installeren
COPY requirements.txt .
RUN uv pip install --system -r requirements.txt

# Server code kopiëren
COPY server.py .

# Health check (optioneel)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ps aux | grep -q "[p]ython server.py" || exit 1

# Start de server
CMD ["python", "server.py"]
```

#### Node.js Dockerfile:

```dockerfile
FROM node:20-slim

# Metadata
LABEL maintainer="jouw.email@example.com"
LABEL description="MCP Server in Docker"

# Werkdirectory instellen
WORKDIR /app

# Dependencies installeren
COPY package*.json ./
RUN npm ci --only=production

# Server code kopiëren
COPY server.js .

# Maak server.js executable
RUN chmod +x server.js

# Health check (optioneel)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ps aux | grep -q "[n]ode server.js" || exit 1

# Start de server
CMD ["node", "server.js"]
```

---

### Stap 5: .dockerignore Maken (Optioneel maar Aanbevolen)

Maak een `.dockerignore` bestand om onnodige bestanden uit te sluiten:

```
# Python
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
env/
venv/
*.egg-info/

# Node.js
node_modules/
npm-debug.log
yarn-error.log

# Git
.git/
.gitignore

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Documentation
README.md
docs/
```

---

### Stap 6: Docker Image Bouwen

```bash
# Basis build
docker build -t mijn-mcp-server:latest .

# Met specifieke tag/versie
docker build -t mijn-mcp-server:1.0.0 .

# Met build arguments
docker build --build-arg PYTHON_VERSION=3.11 -t mijn-mcp-server:latest .

# Zonder cache (fresh build)
docker build --no-cache -t mijn-mcp-server:latest .
```

#### Build Verificatie:

```bash
# Bekijk gebouwde images
docker images | grep mijn-mcp-server

# Inspecteer image details
docker inspect mijn-mcp-server:latest

# Bekijk image layers
docker history mijn-mcp-server:latest
```

---

### Stap 7: Container Testen

#### Basis Test:

```bash
# Run interactief
docker run -i --rm mijn-mcp-server:latest

# Run met environment variables
docker run -i --rm -e DEBUG=true mijn-mcp-server:latest

# Run met volume mount (voor config files)
docker run -i --rm -v $(pwd)/config:/app/config mijn-mcp-server:latest
```

#### Debug Mode:

```bash
# Start container met shell toegang
docker run -it --rm --entrypoint /bin/bash mijn-mcp-server:latest

# Bekijk logs
docker logs <container-id>

# Volg logs in real-time
docker logs -f <container-id>
```

---

### Stap 8: Claude Desktop Configureren

#### Configuratie Locatie:

- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`

#### Basis Configuratie:

```json
{
  "mcpServers": {
    "mijn-server": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "mijn-mcp-server:latest"
      ]
    }
  }
}
```

#### Geavanceerde Configuratie:

```json
{
  "mcpServers": {
    "mijn-server": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "--name", "mijn-mcp-server",
        "-e", "LOG_LEVEL=debug",
        "-v", "${HOME}/mcp-data:/app/data",
        "mijn-mcp-server:latest"
      ],
      "env": {
        "API_KEY": "your-api-key-here"
      }
    }
  }
}
```

#### Meerdere Servers:

```json
{
  "mcpServers": {
    "weather-server": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "weather-mcp:latest"]
    },
    "database-server": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "database-mcp:latest"]
    },
    "api-server": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-e", "API_URL=https://api.example.com",
        "api-mcp:latest"
      ]
    }
  }
}
```

---

### Stap 9: Testen in Claude Desktop

1. **Herstart Claude Desktop** na het aanpassen van de config
2. **Open een nieuw gesprek**
3. **Test de MCP server** met een vraag die de tool gebruikt

#### Voorbeeld test vragen:

```
# Voor een weather server:
"Wat is het weer in Amsterdam?"

# Voor een database server:
"Haal alle gebruikers op uit de database"

# Voor een API server:
"Roep de /users endpoint aan"
```

#### Verificatie:

- Kijk of de tool beschikbaar is in Claude's response
- Check of er geen error messages zijn
- Verifieer dat de output correct is

---

## Best Practices

### 1. Security

```dockerfile
# Gebruik non-root user
RUN useradd -m -u 1000 mcpuser
USER mcpuser

# Minimal base image
FROM python:3.11-slim  # of node:20-alpine

# Scan voor vulnerabilities
# docker scan mijn-mcp-server:latest
```

### 2. Image Optimalisatie

```dockerfile
# Multi-stage build voor kleinere images
FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY server.py .
ENV PATH=/root/.local/bin:$PATH
CMD ["python", "server.py"]
```

### 3. Logging

```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

logger.info("MCP Server gestart")
```

### 4. Environment Variables

```dockerfile
# In Dockerfile
ENV MCP_SERVER_NAME="mijn-server"
ENV LOG_LEVEL="info"

# In Python
import os
server_name = os.getenv("MCP_SERVER_NAME", "default-server")
```

### 5. Versioning

```bash
# Tag met versie
docker build -t mijn-mcp-server:1.0.0 .
docker tag mijn-mcp-server:1.0.0 mijn-mcp-server:latest

# Semantic versioning
# major.minor.patch
# 1.0.0 -> 1.0.1 -> 1.1.0 -> 2.0.0
```

### 6. Health Checks

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import sys; sys.exit(0)" || exit 1
```

---

## Troubleshooting

### Probleem: Container start niet

**Diagnose:**
```bash
# Bekijk logs
docker logs <container-id>

# Run interactief voor debugging
docker run -it --rm --entrypoint /bin/bash mijn-mcp-server:latest

# Check of dependencies zijn geïnstalleerd
docker run -it --rm mijn-mcp-server:latest pip list
```

**Oplossingen:**
- Controleer of alle dependencies in requirements.txt staan
- Verifieer dat de base image correct is
- Check of de CMD/ENTRYPOINT correct is

---

### Probleem: Claude Desktop ziet de server niet

**Diagnose:**
```bash
# Test of de container zelf werkt
docker run -i --rm mijn-mcp-server:latest

# Controleer config file syntax
cat "%APPDATA%\Claude\claude_desktop_config.json" | python -m json.tool
```

**Oplossingen:**
- Herstart Claude Desktop
- Controleer JSON syntax in config file
- Verifieer dat de image naam correct is
- Check of Docker Desktop actief is

---

### Probleem: Permission denied errors

**Oplossing in Dockerfile:**
```dockerfile
# Maak directory writable
RUN mkdir -p /app/data && chmod 777 /app/data

# Of gebruik non-root user
RUN useradd -m mcpuser && chown -R mcpuser:mcpuser /app
USER mcpuser
```

---

### Probleem: Container is traag

**Optimalisaties:**
```dockerfile
# Gebruik slim base image (alpine is kleiner)
FROM python:3.11-alpine

# Cache pip packages
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt

# Gebruik multi-stage builds
```

---

### Probleem: Cannot connect to Docker daemon

**Oplossingen:**
- Start Docker Desktop
- Check Docker service status: `docker info`
- Herstart Docker Desktop
- Windows: Check of Docker Desktop de juiste WSL versie gebruikt

---

## Voorbeelden

### Voorbeeld 1: Filesystem MCP Server

**server.py:**
```python
import asyncio
import os
from pathlib import Path
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

server = Server("filesystem-server")

@server.list_tools()
async def handle_list_tools() -> list[Tool]:
    return [
        Tool(
            name="list-files",
            description="List bestanden in een directory",
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "Directory pad"}
                },
                "required": ["path"]
            }
        ),
        Tool(
            name="read-file",
            description="Lees inhoud van een bestand",
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "Bestand pad"}
                },
                "required": ["path"]
            }
        )
    ]

@server.call_tool()
async def handle_call_tool(name: str, arguments: dict) -> list[TextContent]:
    if name == "list-files":
        path = Path(arguments["path"])
        files = [f.name for f in path.iterdir()]
        return [TextContent(type="text", text="\n".join(files))]

    elif name == "read-file":
        path = Path(arguments["path"])
        content = path.read_text()
        return [TextContent(type="text", text=content)]

    raise ValueError(f"Onbekende tool: {name}")

async def main():
    async with stdio_server() as (read_stream, write_stream):
        await server.run(read_stream, write_stream, server.create_initialization_options())

if __name__ == "__main__":
    asyncio.run(main())
```

**Dockerfile:**
```dockerfile
FROM python:3.11-slim
WORKDIR /app
RUN pip install mcp
COPY server.py .
# Mount een volume voor file access
VOLUME ["/data"]
CMD ["python", "server.py"]
```

**Config:**
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-v", "${HOME}/Documents:/data",
        "filesystem-mcp:latest"
      ]
    }
  }
}
```

---

### Voorbeeld 2: API Client MCP Server

**server.py:**
```python
import asyncio
import httpx
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

server = Server("api-client")

@server.list_tools()
async def handle_list_tools() -> list[Tool]:
    return [
        Tool(
            name="fetch-data",
            description="Haal data op van een API",
            inputSchema={
                "type": "object",
                "properties": {
                    "endpoint": {"type": "string", "description": "API endpoint"},
                    "method": {"type": "string", "enum": ["GET", "POST"], "default": "GET"}
                },
                "required": ["endpoint"]
            }
        )
    ]

@server.call_tool()
async def handle_call_tool(name: str, arguments: dict) -> list[TextContent]:
    if name == "fetch-data":
        async with httpx.AsyncClient() as client:
            method = arguments.get("method", "GET")
            endpoint = arguments["endpoint"]

            if method == "GET":
                response = await client.get(endpoint)
            else:
                response = await client.post(endpoint)

            return [TextContent(type="text", text=response.text)]

    raise ValueError(f"Onbekende tool: {name}")

async def main():
    async with stdio_server() as (read_stream, write_stream):
        await server.run(read_stream, write_stream, server.create_initialization_options())

if __name__ == "__main__":
    asyncio.run(main())
```

**requirements.txt:**
```
mcp>=1.0.0
httpx>=0.27.0
```

---

### Voorbeeld 3: Database MCP Server

**server.py:**
```python
import asyncio
import sqlite3
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

server = Server("database-server")

def get_db():
    return sqlite3.connect('/data/database.db')

@server.list_tools()
async def handle_list_tools() -> list[Tool]:
    return [
        Tool(
            name="query",
            description="Voer een SQL query uit",
            inputSchema={
                "type": "object",
                "properties": {
                    "sql": {"type": "string", "description": "SQL query"}
                },
                "required": ["sql"]
            }
        )
    ]

@server.call_tool()
async def handle_call_tool(name: str, arguments: dict) -> list[TextContent]:
    if name == "query":
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute(arguments["sql"])
        results = cursor.fetchall()
        conn.close()

        return [TextContent(type="text", text=str(results))]

    raise ValueError(f"Onbekende tool: {name}")

async def main():
    async with stdio_server() as (read_stream, write_stream):
        await server.run(read_stream, write_stream, server.create_initialization_options())

if __name__ == "__main__":
    asyncio.run(main())
```

**Config met volume mount:**
```json
{
  "mcpServers": {
    "database": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-v", "mcp-database:/data",
        "database-mcp:latest"
      ]
    }
  }
}
```

---

## Handige Docker Commando's

```bash
# Image management
docker images                          # Lijst alle images
docker rmi <image-id>                  # Verwijder image
docker image prune                     # Verwijder ongebruikte images

# Container management
docker ps                              # Lijst draaiende containers
docker ps -a                           # Lijst alle containers
docker stop <container-id>             # Stop container
docker rm <container-id>               # Verwijder container
docker container prune                 # Verwijder gestopte containers

# Debugging
docker logs <container-id>             # Bekijk logs
docker exec -it <container-id> bash    # Open shell in draaiende container
docker inspect <container-id>          # Gedetailleerde info

# Cleanup
docker system prune                    # Verwijder alles ongebruikt
docker system df                       # Bekijk disk usage
```

---

## Extra Resources

### Documentatie:
- **MCP Specification**: https://spec.modelcontextprotocol.io/
- **Docker Documentation**: https://docs.docker.com/
- **Python MCP SDK**: https://github.com/modelcontextprotocol/python-sdk
- **TypeScript MCP SDK**: https://github.com/modelcontextprotocol/typescript-sdk

### Tools:
- **Docker Desktop**: Container management GUI
- **VS Code Docker Extension**: Docker integratie in VS Code
- **Portainer**: Web-based container management

### Community:
- **MCP GitHub**: https://github.com/modelcontextprotocol
- **Docker Hub**: https://hub.docker.com/
- **Stack Overflow**: Tag `model-context-protocol` en `docker`

---

## Conclusie

Met deze uitgebreide gids kun je nu:
- ✅ MCP servers in Docker containers bouwen
- ✅ Containers testen en debuggen
- ✅ MCP servers integreren met Claude Desktop
- ✅ Best practices toepassen voor productie-ready containers
- ✅ Problemen oplossen wanneer ze zich voordoen

**Happy containerizing! 🐳**
