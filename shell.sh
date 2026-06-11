#!/usr/bin/env bash
set -euo pipefail

docker compose exec rails bash -c "cd /workspace/myapp && exec bash"
