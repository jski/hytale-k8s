FROM debian:bookworm-slim

SHELL ["/bin/bash", "-lc"]

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      unzip \
      xz-utils \
      tar; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /work

COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV OUTPUT_DIR="/output"

ENTRYPOINT ["/entrypoint.sh"]