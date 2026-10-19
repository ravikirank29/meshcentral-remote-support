# MeshCentral Remote Support Server

A self-hosted remote desktop support platform built on the open-source
[MeshCentral](https://meshcentral.com) project — the same kind of setup as
sites like `remlnk.com/usa/`: a private web console from which you can remote
desktop, terminal, and file-manage computers anywhere in the world.

## What this gives you

- Your own MeshCentral server (Node.js), no third-party cloud involved
- A public HTTPS address via a TCP tunnel (for demo/testing)
- Scripts to install, start, and renew everything
- A tested agent-install flow (verified end-to-end with remote commands)

## Quick start

```bash
# 1. Install (checks Node 18+, installs MeshCentral via npm)
./install.sh

# 2. Edit meshcentral-data/config.json
#    Set "cert" to your public hostname (or your own domain for permanent use)

# 3. Start the server + public tunnel
./start.sh
```

On first launch the server prints `Server has no users` — open the public URL
in a browser and create the administrator account (the first account created
becomes site admin). Then create a device group and download agents from the
web UI ("Add Agent").

## Files

| File | Purpose |
|---|---|
| `install.sh` | Fresh install: Node check, `npm install meshcentral`, config from template |
| `start.sh` | Starts the pinggy TCP tunnel + MeshCentral, prints the public URL |
| `config.template.json` | Template server config (copy to `meshcentral-data/config.json`) |
| `proxy-command.py` | Optional SSH `ProxyCommand` helper for networks behind an HTTP egress proxy |
| `.gitignore` | Keeps secrets, logs, database and `node_modules` out of git |

## How it works

MeshCentral serves HTTPS itself (self-signed cert for the configured `cert`
hostname). A TCP tunnel (pinggy) forwards a public `host:port` straight to
the server's port, so TLS passes through end-to-end — this is what lets
agents verify the server's certificate correctly.

```
Internet --TLS--> pinggy TCP tunnel --TCP--> ssh -R --> MeshCentral :4430
Browser/agent -------------------------------------------------->
```

## Going permanent

The free tunnel is for testing: sessions expire (~60 min) and the address
changes on restart. For production, run this on your own VPS with your own
domain and let MeshCentral fetch a free Let's Encrypt certificate:

```json
"settings": {
  "cert": "support.example.com",
  "port": 443,
  "letsencrypt": { "email": "you@example.com", "names": ["support.example.com"] }
}
```

Then agents downloaded from the web UI "just work" from anywhere.

## Security notes

- Anyone with the admin login has full remote control of every connected
  computer. Use a strong password and enable two-factor auth
  (user menu → My Account → Security).
- `ADMIN_CREDENTIALS.txt`, logs and `meshcentral-data/` are git-ignored —
  never commit them.
- Only install agents on computers whose owners trust you.

## Verified

Server start, admin creation, device group, agent install, agent online
status, and remote command execution (`hostname && whoami && uname -r`)
were all verified working on 2026-10-18.
