#!/bin/bash
set -euo pipefail

# Create build-config directory with embedded opencode.json config
cat > ./docker-opencode.json << 'EOF'
{
  "mcp": {
    "chrome-devtools": {
      "type": "local",
      "command": [
        "npx",
        "-y",
        "chrome-devtools-mcp@latest",
        "--isolated",
        "--chromeArg=--headless",
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

# Build the Docker image (use amd64 platform for Google Chrome compatibility)
docker build -q --platform linux/amd64 -t graph-experiments . -f - <<EOF
FROM --platform=linux/amd64 ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    git \
    wget \
    && wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && curl -fsSL https://get.docker.com | sh \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g opencode-ai \
    && git clone https://github.com/anthropics/skills /tmp/skills \
    && mkdir -p /root/.config/opencode \
    && ln -s /tmp/skills/skills /root/.config/opencode/skills \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY ./docker-opencode.json /root/.config/opencode/opencode.json

ENV CHROME_BIN=/usr/bin/google-chrome
EOF

# Clean up build config
rm -rf ./docker-opencode.json

PROMPT=$@
docker run --rm --privileged -w /workspace -v $PWD:/workspace -v $HOME/.docker/run/docker.sock:/var/run/docker.sock graph-experiments opencode run --model unsloth/qwen3.5-27b-vision --thinking "$PROMPT"
