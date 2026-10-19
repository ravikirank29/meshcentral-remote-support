#!/usr/bin/env python3
"""SSH ProxyCommand: tunnel %h %p through the sandbox HTTP egress proxy via CONNECT."""
import socket, os, sys, base64, urllib.parse, threading

def main():
    host, port = sys.argv[1], int(sys.argv[2])
    proxy = os.environ.get('https_proxy') or os.environ.get('HTTPS_PROXY') \
        or os.environ.get('http_proxy') or os.environ.get('HTTP_PROXY')
    if not proxy:
        sys.stderr.write('proxy-command: no proxy env set\n'); sys.exit(1)
    u = urllib.parse.urlparse(proxy)
    s = socket.create_connection((u.hostname, u.port), timeout=15)
    headers = f'CONNECT {host}:{port} HTTP/1.1\r\nHost: {host}:{port}\r\n'
    if u.username:
        creds = urllib.parse.unquote(u.username) + ':' + urllib.parse.unquote(u.password or '')
        headers += 'Proxy-Authorization: Basic ' + base64.b64encode(creds.encode()).decode() + '\r\n'
    headers += '\r\n'
    s.sendall(headers.encode())
    resp = b''
    while b'\r\n\r\n' not in resp:
        chunk = s.recv(4096)
        if not chunk: sys.stderr.write('proxy-command: proxy closed connection\n'); sys.exit(1)
        resp += chunk
    status = resp.split(b'\r\n', 1)[0].decode(errors='replace')
    if ' 200 ' not in status:
        sys.stderr.write(f'proxy-command: CONNECT failed: {status}\n'); sys.exit(1)
    # Bidirectional forward between stdio and socket
    def pump(src, dst):
        try:
            while True:
                data = src.recv(65536) if src is not sys.stdin.buffer else os.read(0, 65536)
                if not data: break
                if dst is s: dst.sendall(data)
                else: os.write(1, data)
        except Exception: pass
    t = threading.Thread(target=pump, args=(s, sys.stdout.buffer), daemon=True); t.start()
    try:
        while True:
            data = os.read(0, 65536)
            if not data: break
            s.sendall(data)
    except Exception: pass

if __name__ == '__main__':
    main()
