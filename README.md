# MCP Container

A Docker-based Model Context Protocol (MCP) server implementation that provides weather information through a standardized interface.

## What is MCP?

The Model Context Protocol (MCP) is a standardized way for AI applications to interact with external tools and data sources. This container provides a weather information service that can be used by Claude and other MCP-compatible AI assistants.

## Prerequisites

- **Docker Desktop** installed and running
  - [Download for Windows](https://docs.docker.com/desktop/install/windows-install/)
  - [Download for Mac](https://docs.docker.com/desktop/install/mac-install/)
  - [Download for Linux](https://docs.docker.com/desktop/install/linux-install/)
- **Claude Desktop** (for using the MCP server)
  - [Download Claude Desktop](https://claude.ai/download)
- **Git** (for cloning the repository)

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/Pimmetjeoss/MCP_container.git
cd MCP_container
```

### 2. Build the Docker Image

```bash
docker build -t mcp-server .
```

This will create a Docker image with Python 3.11 and all necessary dependencies.

### 3. Run the Container

```bash
docker run -d --name mcp-weather-server mcp-server
```

The container will start and run the MCP weather server.

## Configuration

### Connect to Claude Desktop

To use this MCP server with Claude Desktop, add the following configuration to your Claude Desktop settings:

**Windows:** `%APPDATA%\Claude\claude_desktop_config.json`
**Mac/Linux:** `~/.config/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "weather": {
      "command": "docker",
      "args": ["exec", "-i", "mcp-weather-server", "python", "/app/weather.py"]
    }
  }
}
```

After updating the configuration, restart Claude Desktop.

## Usage

Once configured, you can ask Claude to get weather information:

- "What's the weather in Amsterdam?"
- "Show me the forecast for New York"
- "Get weather data for Tokyo"

The MCP server will respond with temperature, conditions, and humidity information.

## Available Tools

This MCP server provides the following tool:

- **get-weather**: Get current weather information for any city
  - Input: `city` (string) - Name of the city
  - Output: Temperature (°C), conditions, and humidity (%)

## Docker Commands

### View Container Logs
```bash
docker logs mcp-weather-server
```

### Stop the Container
```bash
docker stop mcp-weather-server
```

### Start the Container
```bash
docker start mcp-weather-server
```

### Remove the Container
```bash
docker rm -f mcp-weather-server
```

### Rebuild After Changes
```bash
docker build -t mcp-server .
docker rm -f mcp-weather-server
docker run -d --name mcp-weather-server mcp-server
```

## Project Structure

```
mcp_container/
├── Dockerfile              # Docker configuration
├── weather.py             # MCP server implementation
├── requirements.txt       # Python dependencies
├── README.md             # This file
├── QUICK_START.md        # Quick setup guide
└── MCP_CONTAINER_GUIDE.md # Detailed documentation
```

## Documentation

- **[QUICK_START.md](QUICK_START.md)** - Fast setup guide to get running quickly
- **[MCP_CONTAINER_GUIDE.md](MCP_CONTAINER_GUIDE.md)** - Comprehensive guide with examples and troubleshooting

## Troubleshooting

### Container won't start
- Make sure Docker Desktop is running
- Check if port is not already in use: `docker ps`

### Claude can't connect to MCP server
- Verify the container is running: `docker ps`
- Check container logs: `docker logs mcp-weather-server`
- Ensure the config file path is correct for your OS
- Restart Claude Desktop after changing configuration

### Permission errors on Windows
- Run Docker Desktop as Administrator
- Make sure WSL2 is properly configured

## Contributing

Feel free to submit issues and pull requests to improve this MCP server.

## License

This project is open source and available under the MIT License.

## Resources

- [MCP Documentation](https://modelcontextprotocol.io/)
- [Docker Documentation](https://docs.docker.com/)
- [Claude Desktop](https://claude.ai/download)
