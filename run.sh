#!/bin/bash
set -euo pipefail

# Create build-config directory with embedded opencode.json config
cat > ./docker-opencode.json << 'EOF'
{
  "mcp": {
    "chrome-devtools": {
      "type": "local",
      "command": [
        "chrome-devtools-mcp",
        "--isolated",
        "--headless",
        "--executablePath=/ms-playwright/chromium-1155/chrome-linux/chrome",
        "--chromeArg=--no-sandbox",
        "--chromeArg=--disable-gpu",
        "--chromeArg=--no-first-run",
        "--chromeArg=--no-default-browser-check",
        "--no-usage-statistics"
      ]
    }
  },
  "provider": {
    "unsloth": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Unsloth",
      "options": {
        "baseURL": "http://desktop.local:8888/v1"
      },
      "models": {
        "qwen3.5-27b-vision": {
          "name": "Qwen3.5 27B Vision"
        }
      }
    }
  }
}
EOF

# Build the Docker image (arm64 platform, Playwright base includes Node + Chromium)
docker build -q --platform linux/arm64 -t graph-experiments . -f - <<EOF
FROM --platform=linux/arm64 mcr.microsoft.com/playwright:v1.50.0-noble

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    git \
    tmux \
    && curl -fsSL https://get.docker.com | sh \
    && npm install -g opencode-ai chrome-devtools-mcp \
    && git clone https://github.com/anthropics/skills /tmp/skills \
    && mkdir -p /root/.config/opencode \
    && ln -s /tmp/skills/skills /root/.config/opencode/skills \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY ./docker-opencode.json /root/.config/opencode/opencode.json

ENV CHROME_BIN=/ms-playwright/chromium-1155/chrome-linux/chrome
EOF

# Clean up build config
rm -rf ./docker-opencode.json

PROMPT=$@
docker run --rm --privileged -w /workspace -v $PWD:/workspace -v $HOME/.docker/run/docker.sock:/var/run/docker.sock graph-experiments tmux -c "opencode run --model unsloth/qwen3.5-27b-vision --thinking $PROMPT"
