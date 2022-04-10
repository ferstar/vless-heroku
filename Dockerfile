FROM ubuntu:20.04

ENV LANG=en_US.UTF-8 \
    TZ=Asia/Shanghai \
    SUPERVISOR_LOGFILE_BACKUPS=3 \
    DEBIAN_FRONTEND=noninteractive

COPY v2ray.sh /root/v2ray.sh
COPY startup.sh /startup.sh

RUN apt update && \
    apt install -y --no-install-recommends \
    python3.8-dev \
    python3.8-distutils \
    openssl \
    ca-certificates \
    wget \
    curl \
    tzdata \
    locales \
    python3-pip \
    vim-tiny \
    htop && \
    ln -sf /usr/bin/python3.8 /usr/bin/python3 && \
    ln -sf /usr/bin/vim-tiny /usr/bin/vim && \
    ln -sf /usr/bin/python3.8-config /usr/bin/python-config && \
    locale-gen en_US.UTF-8 && \
    pip3 install --upgrade --no-cache-dir supervisor && \
    mkdir -pv /etc/supervisor/conf.d && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/.cache && \
    mkdir -p /etc/v2ray /usr/local/share/v2ray /var/log/v2ray && \
    chmod +x /root/v2ray.sh && \
    chmod +x /startup.sh && \
    /root/v2ray.sh && \
    wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /root/cloudflared && \
    chmod +x /root/cloudflared

ENTRYPOINT ["/startup.sh"]

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD /usr/bin/nc -z localhost 8080 || exit 1
