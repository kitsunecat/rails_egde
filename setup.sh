#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")" && pwd)"

echo "==> Cloning rails/rails..."
if [ -d "$WORKSPACE/rails/.git" ]; then
  echo "    rails/ already exists, skipping clone."
else
  git clone https://github.com/rails/rails.git "$WORKSPACE/rails"
fi

echo "==> Building and starting container..."
docker compose up -d --build

echo "==> Installing Rails source dependencies..."
docker compose exec rails bash -c "
  set -e
  cd /workspace/rails
  bundle config set without 'db'
  bundle install
"

echo "==> Generating myapp with --dev..."
if [ -d "$WORKSPACE/myapp" ]; then
  echo "    myapp/ already exists, skipping rails new."
else
  docker compose exec rails bash -c "
    set -e
    cd /workspace/rails
    bundle exec railties/exe/rails new /workspace/myapp --dev --skip-bundle
  "
fi

echo "==> Fixing Gemfile rails path to container path (/workspace/rails)..."
docker compose exec rails bash -c "
  sed -i 's|gem \"rails\", path: \"[^\"]*\"|gem \"rails\", path: \"/workspace/rails\"|' /workspace/myapp/Gemfile
"

echo "==> Installing myapp dependencies..."
docker compose exec rails bash -c "
  set -e
  cd /workspace/myapp
  bundle install
"

echo "==> Verifying edge Rails version..."
docker compose exec rails bash -c "cd /workspace/myapp && bin/rails runner 'puts Rails.version'"

echo ""
echo "Setup complete! Run ./start.sh to start the Rails server."
