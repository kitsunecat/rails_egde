#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="$(cd "$(dirname "$0")" && pwd)"

# コンテナのデフォルトコマンドは rails server で、gem 未インストール時は即クラッシュする。
# そのため exec ではなく、コマンドを上書きできる run --rm でセットアップを行う。
run_in_container() {
  docker compose run --rm rails bash -c "$1"
}

echo "==> Cloning rails/rails..."
if [ -d "$WORKSPACE/rails/.git" ]; then
  echo "    rails/ already exists, skipping clone."
else
  git clone https://github.com/rails/rails.git "$WORKSPACE/rails"
fi

echo "==> Building image..."
docker compose build

echo "==> Installing Rails source dependencies..."
run_in_container "
  set -e
  cd /workspace/rails
  bundle config set without 'db'
  bundle install
"

echo "==> Generating myapp with --dev..."
if [ -d "$WORKSPACE/myapp" ]; then
  echo "    myapp/ already exists, skipping rails new."
else
  run_in_container "
    set -e
    cd /workspace/rails
    bundle exec railties/exe/rails new /workspace/myapp --dev --skip-bundle
  "
fi

echo "==> Fixing Gemfile rails path to container path (/workspace/rails)..."
run_in_container "
  sed -i 's|gem \"rails\", path: \"[^\"]*\"|gem \"rails\", path: \"/workspace/rails\"|' /workspace/myapp/Gemfile
"

echo "==> Installing myapp dependencies..."
run_in_container "
  set -e
  cd /workspace/myapp
  bundle install
"

echo "==> Verifying edge Rails version..."
run_in_container "cd /workspace/myapp && bin/rails runner 'puts Rails.version'"

echo ""
echo "Setup complete! Run ./start.sh to start the Rails server."
