#!/bin/bash
# Start (or restart) the MeshCentral server + public TCP tunnel.
# Prints the current public URL. The free tunnel gives a NEW address
# each time this runs and sessions expire after ~60 minutes.
#
# If your network needs an HTTP proxy for outbound SSH, set PROXY_COMMAND
# to a ProxyCommand helper, e.g.:
#   PROXY_COMMAND="$DIR/proxy-command.py %h %p" ./start.sh
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR" || exit 1

echo "==> Stopping old tunnel/server (if any)..."
pkill -f "tcp@a.pinggy.io" 2>/dev/null
pkill -f "node_modules/meshcentral" 2>/dev/null
sleep 2

echo "==> Starting public tunnel (pinggy)..."
SSH_OPTS="-o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=3"
if [ -n "${PROXY_COMMAND:-}" ]; then
    SSH_OPTS="$SSH_OPTS -o ProxyCommand=$PROXY_COMMAND"
    echo "    using ProxyCommand for outbound SSH"
fi
rm -f pinggy.log
# shellcheck disable=SC2086
nohup ssh $SSH_OPTS -p 443 -R0:127.0.0.1:4430 tcp@a.pinggy.io > pinggy.log 2>&1 &
for _ in $(seq 1 30); do
    URL=$(grep -Eo "tcp://[^ ]+" pinggy.log 2>/dev/null | head -1)
    [ -n "$URL" ] && break
    sleep 2
done
if [ -z "${URL:-}" ]; then
    echo "ERROR: tunnel did not come up. See pinggy.log"; exit 1
fi
HOST=$(echo "$URL" | sed -E 's|tcp://([^:]+):.*|\1|')
PORT=$(echo "$URL" | sed -E 's|tcp://[^:]+:([0-9]+)|\1|')
echo "    tunnel: $URL"

echo "==> Updating MeshCentral config for host $HOST..."
python3 - "$HOST" <<'EOF'
import json, sys
host = sys.argv[1]
p = 'meshcentral-data/config.json'
cfg = json.load(open(p))
cfg['settings']['cert'] = host
cfg['settings']['port'] = 4430
json.dump(cfg, open(p, 'w'), indent=2)
print("    config updated")
EOF

echo "==> Starting MeshCentral..."
rm -f server.log
nohup node node_modules/meshcentral > server.log 2>&1 &
for _ in $(seq 1 40); do
    grep -q "HTTPS server running" server.log 2>/dev/null && break
    sleep 3
done
if ! grep -q "HTTPS server running" server.log 2>/dev/null; then
    echo "ERROR: server did not start. See server.log"; exit 1
fi

PUBLIC_URL="https://${HOST}:${PORT}/"
echo "$PUBLIC_URL" > current-url.txt

echo ""
echo "=============================================================="
echo "  MeshCentral is UP"
echo "  Public URL: $PUBLIC_URL"
echo "  (free tunnel: expires ~60 min; re-run ./start.sh for a new URL)"
echo "=============================================================="
echo "First run? Open the URL and create the administrator account."
