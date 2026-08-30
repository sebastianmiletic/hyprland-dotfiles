#!/usr/bin/env python3
"""Persistent wob OSD daemon. Accepts 'vol:value' or 'bri:value' over Unix socket."""
import os, sys, socket, subprocess, time, signal

SOCK = os.path.join(os.environ.get('XDG_RUNTIME_DIR', '/tmp'), 'wob-osd.sock')
WOBSOCK = os.path.join(os.environ.get('XDG_RUNTIME_DIR', '/tmp'), 'wob-daemon.sock')
FIFO = os.path.join(os.environ.get('XDG_RUNTIME_DIR', '/tmp'), 'wob-daemon.fifo')

def start_wob():
    # Remove old fifo
    if os.path.exists(FIFO):
        os.remove(FIFO)
    os.mkfifo(FIFO)
    env = os.environ.copy()
    env['PATH'] = os.path.expanduser('~/.local/bin') + ':' + env.get('PATH', '')
    proc = subprocess.Popen(
        ['wob', '--config', os.path.expanduser('~/.config/wob/wob.ini')],
        stdin=open(FIFO, 'r'),
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        env=env
    )
    return proc

def send(value):
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.connect(SOCK)
            s.sendall(f"{value}\n".encode())
    except (ConnectionRefusedError, FileNotFoundError):
        return False
    return True

def client(value):
    if not send(value):
        # Start daemon
        subprocess.Popen([sys.executable, __file__, '--daemon'],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(0.3)
        send(value)

def daemon():
    if os.path.exists(SOCK):
        os.remove(SOCK)
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(SOCK)
    server.listen(5)

    # Open FIFO for writing persistently
    fifo_wr = open(FIFO, 'w')
    wob_proc = start_wob()

    def cleanup(signum, frame):
        wob_proc.terminate()
        fifo_wr.close()
        server.close()
        if os.path.exists(SOCK):
            os.remove(SOCK)
        sys.exit(0)
    signal.signal(signal.SIGTERM, cleanup)
    signal.signal(signal.SIGINT, cleanup)

    while True:
        try:
            conn, _ = server.accept()
            data = conn.recv(32).decode().strip()
            conn.close()
            if data:
                try:
                    val = int(float(data))
                    fifo_wr.write(f"{val}\n")
                    fifo_wr.flush()
                except ValueError:
                    pass
        except Exception:
            continue

if __name__ == '__main__':
    if sys.argv[1:] == ['--daemon']:
        daemon()
    elif len(sys.argv) == 2:
        client(sys.argv[1])
    else:
        print("usage: OSD.py <value>  or  OSD.py --daemon")
