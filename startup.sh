#!/bin/bash

set -e

rm -rf /etc/supervisor/conf.d/*

cat << EOF > /etc/supervisor/supervisord.conf
[unix_http_server]
file=/dev/shm/supervisor.sock   ; (the path to the socket file)
chmod=0700                      ; sockef file mode (default 0700)

[supervisord]
logfile=/root/supervisord.log ; (main log file;default $CWD/supervisord.log)
pidfile=/dev/shm/supervisord.pid ; (supervisord pidfile;default supervisord.pid)
childlogdir=/root            ; ('AUTO' child log dir, default $TEMP)

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///dev/shm/supervisor.sock ; use a unix:// URL  for a unix socket

[include]
files = /etc/supervisor/conf.d/*.conf
EOF

cat << EOF > /etc/supervisor/conf.d/v2ray.conf
[program:v2ray]
command=/usr/bin/v2ray -config /etc/v2ray/config.json
autorestart=true
autostart=true
startsecs=10
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stderr
EOF

cat << EOF > /tmp/config.json
{
    "policy": {
        "levels": {
            "0": {
                "handshake": 5,
                "connIdle": 300,
                "uplinkOnly": 2,
                "downlinkOnly": 5,
                "statsUserUplink": false,
                "statsUserDownlink": false,
                "bufferSize": 10240
            }
        },
        "system": {
            "statsInboundUplink": false,
            "statsInboundDownlink": false,
            "statsOutboundUplink": false,
            "statsOutboundDownlink": false
        }
    },
    "inbounds": [
        {
            "port": 8080,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID",
                        "level": 0
                    }
                ],
                 "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none"
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom"
        }
    ]
}
EOF

if [[ $TUNNEL_TOKEN ]]; then
    echo 'has tunnel token, run cloudflared tunnel'
    cat << EOF >> /etc/supervisor/conf.d/v2ray.conf
[program:cloudflared]
command=/root/cloudflared tunnel --no-autoupdate run --token %(ENV_TUNNEL_TOKEN)s
autorestart=true
autostart=true
startsecs=10
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stderr
EOF
fi

supervisord -n -c /etc/supervisor/supervisord.conf
