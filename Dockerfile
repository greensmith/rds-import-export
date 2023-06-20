FROM debian:bullseye-slim

COPY entrypoint.sh /entrypoint.sh

RUN apt-get update && apt-get install -y \
    mariadb-client curl jq unzip \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && chmod +x /entrypoint.sh \
    && mkdir -p /data \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /data

ENTRYPOINT ["/entrypoint.sh"]