FROM python:3.10-slim

# Installeer systeem dependencies
RUN apt-get update && \
    apt-get install -y curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Installeer uv CLI
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

WORKDIR /app

# Kopieer en installeer requirements
COPY requirements.txt .
RUN uv pip install --system -r requirements.txt

# Kopieer de server code
COPY weather.py .

# Start de MCP server
CMD ["python", "weather.py"]
