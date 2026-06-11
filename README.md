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

## スクリプト

| スクリプト | 用途 |
|---|---|
| `./setup.sh` | 初回セットアップ（clone → ビルド → bundle install → アプリ生成）を一括実行 |
| `./start.sh` | 通常起動（コンテナ起動 → Rails サーバー開始） |
| `./shell.sh` | コンテナに入り `/workspace` で bash を起動 |

## セットアップ手順

### 1. 初回セットアップ（スクリプトで一括実行）

```bash
./setup.sh
```

内部で以下を順番に実行します：

1. `rails/rails` を clone（既にあればスキップ）
2. `docker compose up -d --build` でイメージビルド＆コンテナ起動
3. `/workspace/rails` で `bundle install`
4. `rails new /workspace/myapp --dev` でアプリ生成（既にあればスキップ）
5. `/workspace/myapp` で `bundle install`
6. `bin/rails runner "puts Rails.version"` でバージョン確認

## 日常的な使い方

### サーバー起動

```bash
./start.sh        # コンテナ起動 → Rails server が自動で立ち上がる
# → http://localhost:3000 でアクセス
```

ログを確認したい場合：

```bash
docker compose logs -f
```

`docker compose up -d` だけでも同様にサーバーが起動します。
`myapp` がまだない場合（初回セットアップ前）は `sleep infinity` で待機します。

### Rails 本体のソースを読む・書き換える

```
rails/actionpack/lib/action_dispatch/...  など
```
ホスト側エディタで直接開けます。コンテナ再起動不要で即反映されます。

### main ブランチへの追従

```bash
cd rails/
git pull
```

gem に変更があった場合は追加で：

```bash
docker compose exec rails bash -c "cd /workspace/myapp && bundle install"
```

### コンテナ停止・削除

```bash
docker compose down          # コンテナ停止（bundle ボリュームは残る）
docker compose down -v       # ボリュームも含めて完全削除
```
