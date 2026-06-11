#!/usr/bin/env bash
set -euo pipefail

echo "==> Starting container (Rails server will start automatically)..."
docker compose up -d
echo ""
echo "Rails server: http://localhost:3000"
echo "Logs: docker compose logs -f"
