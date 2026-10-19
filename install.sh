#!/bin/bash
# Fresh install of the MeshCentral remote-support server.
# Usage: ./install.sh
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR" || exit 1

echo "==> Checking Node.js..."
if ! command -v node >/dev/null 2>&1; then
    echo "Node.js not found. Install Node 18+ first (https://nodejs.org), then re-run."
    exit 1
fi
NODE_MAJOR=$(node -p "process.versions.node.split('.')[0]")
if [ "$NODE_MAJOR" -lt 18 ]; then
    echo "Node $(node -v) is too old; MeshCentral needs Node 18+. Please upgrade."
    exit 1
fi
echo "    $(node -v) OK"

echo "==> Installing MeshCentral (npm, may take a few minutes)..."
npm init -y >/dev/null 2>&1
npm install meshcentral || { echo "npm install failed"; exit 1; }

echo "==> Creating config from template..."
mkdir -p meshcentral-data
if [ ! -f meshcentral-data/config.json ]; then
    cp config.template.json meshcentral-data/config.json
    echo "    created meshcentral-data/config.json — edit the \"cert\" hostname before starting"
else
    echo "    meshcentral-data/config.json already exists, left untouched"
fi

echo ""
echo "Done. Next steps:"
echo "  1. Edit meshcentral-data/config.json (set \"cert\" to your public hostname)"
echo "  2. Run ./start.sh"
echo "  3. Open the printed URL and create the first (administrator) account"
