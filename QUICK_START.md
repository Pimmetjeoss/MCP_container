# MCP Server in Docker - Quick Start

## 5 Minuten Setup

### 1. Maak Project Folder
```bash
mkdir mijn-mcp-server
cd mijn-mcp-server
```

### 2. Maak Server Code
**server.py**
```python
import asyncio
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

server = Server("mijn-server")

@server.list_tools()
async def handle_list_tools() -> list[Tool]:
    return [
        Tool(
            name="echo",
            description="Echo een bericht terug",
            inputSchema={
                "type": "object",
                "properties": {"message": {"type": "string"}},
                "required": ["message"]
            }
        )
    ]

@server.call_tool()
async def handle_call_tool(name: str, arguments: dict) -> list[TextContent]:
    if name == "echo":
        return [TextContent(type="text", text=f"Echo: {arguments['message']}")]
    raise ValueError(f"Onbekende tool: {name}")

async def main():
    async with stdio_server() as (read_stream, write_stream):
        await server.run(read_stream, write_stream, server.create_initialization_options())

if __name__ == "__main__":
    asyncio.run(main())
```

### 3. Maak Dependencies
**requirements.txt**
```
mcp
```

### 4. Maak Dockerfile
```dockerfile
FROM python:3.11-slim
WORKDIR /app
RUN pip install mcp
COPY server.py .
CMD ["python", "server.py"]
```

### 5. Bouw Image
```bash
docker build -t mijn-mcp-server:latest .
```

### 6. Test Container
```bash
docker run -i --rm mijn-mcp-server:latest
```
*(Ctrl+C om te stoppen)*

### 7. Configureer Claude Desktop
**Locatie config:**
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`

**Voeg toe:**
```json
{
  "mcpServers": {
    "mijn-server": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "mijn-mcp-server:latest"]
    }
  }
}
```

### 8. Test in Claude
1. Herstart Claude Desktop
2. Vraag: *"Echo 'Hello World'"*
3. ✅ Je zou "Echo: Hello World" moeten zien

---

## Veelgebruikte Commando's

```bash
# Images bekijken
docker images

# Container stoppen
docker stop <container-id>

# Logs bekijken
docker logs <container-id>

# Image verwijderen
docker rmi mijn-mcp-server:latest

# Cleanup alles
docker system prune -a
```

---

## Volgende Stappen

- 📖 Lees [MCP_CONTAINER_GUIDE.md](MCP_CONTAINER_GUIDE.md) voor details
- 🔧 Voeg meer tools toe aan je server
- 🌐 Connect met externe APIs
- 💾 Gebruik volumes voor data persistence

---

**Klaar in 5 minuten! 🚀**
