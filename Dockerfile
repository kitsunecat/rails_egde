FROM ruby:3.4

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      git \
      pkg-config \
      libyaml-dev \
      sqlite3 \
      libsqlite3-dev \
      libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
