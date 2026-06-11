# edge Rails 開発環境

未リリースの最新 Rails（main ブランチ）をローカルで試し読み・書き換えできる Docker 開発環境です。

## 構成の概要

```
rails_egde/
├── Dockerfile          # ruby:3.4 ベースの開発コンテナ
├── docker-compose.yml  # サービス定義
├── rails/              # clone した rails/rails 本体（gitignore 対象）
└── myapp/              # --dev で生成したサンプルアプリ（gitignore 対象）
```

### なぜこの構成か

| 設計選択 | 理由 |
|---|---|
| `ruby:3.4` イメージ | edge Rails の動作には最新 Ruby が必要 |
| gem をイメージに焼き込まない | `bundle install` の結果を名前付きボリューム `bundle` に保存し、イメージの再ビルドなしに gem を更新できる |
| `--dev` フラグ | 生成アプリの Gemfile が `gem "rails", path: "../rails"` のローカル参照になる。Rails 本体を編集→即反映できる |
| `sleep infinity` コマンド | コンテナを常駐させて `docker compose exec rails bash` で入る運用。プロセスを起動・停止しやすい |
| `rails/` を gitignore | rails/rails 本体は別リポジトリなので本プロジェクトに含めない |

## セットアップ手順

### 1. Rails ソースを clone

```bash
git clone https://github.com/rails/rails.git
```

### 2. コンテナを起動

```bash
docker compose up -d --build
```

### 3. コンテナに入り、依存関係をインストール

```bash
docker compose exec rails bash

# Rails 本体の依存を入れる
cd /workspace/rails && bundle install

# edge アプリを生成（--dev で path 参照 Gemfile になる）
bundle exec railties/exe/rails new /workspace/myapp --dev

# アプリの依存を入れる
cd /workspace/myapp && bundle install
```

### 4. バージョン確認

```bash
bin/rails runner "puts Rails.version"
# => 8.2.0.alpha  （未リリースの edge 版）
```

### 5. Gemfile の path 参照を確認

```bash
grep 'gem "rails"' Gemfile
# => gem "rails", path: "/workspace/rails"
```

## 日常的な使い方

### Rails 本体のソースを読む・書き換える

```
rails/actionpack/lib/action_dispatch/...  など
```
ホスト側エディタで直接開けます。コンテナ再起動不要で即反映されます。

### main ブランチへの追従

```bash
cd rails/
git pull
# myapp 側の bundle は通常そのまま使えるが、念のため:
cd ../myapp && bundle install
```

### サーバー起動

```bash
docker compose exec rails bash
cd /workspace/myapp
bin/rails server -b 0.0.0.0
# → ホストの http://localhost:3000 でアクセス
```

### コンテナ停止・削除

```bash
docker compose down          # コンテナ停止（bundle ボリュームは残る）
docker compose down -v       # ボリュームも含めて完全削除
```
