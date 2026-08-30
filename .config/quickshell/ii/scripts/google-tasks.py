#!/usr/bin/env python3
"""Small dependency-free Google Tasks OAuth/sync helper for the ii shell."""

import argparse
import base64
import hashlib
import http.server
import json
import os
import secrets
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import webbrowser
from pathlib import Path

CONFIG_DIR = Path.home() / ".config" / "illogical-impulse" / "google-tasks"
CREDS_PATH = CONFIG_DIR / "client_secret.json"
TOKEN_PATH = CONFIG_DIR / "token.json"
TODO_PATH = Path.home() / ".local" / "state" / "quickshell" / "user" / "todo.json"
SCOPE = "https://www.googleapis.com/auth/tasks"


def goa_google_account(with_token=False):
    """Return the first GNOME Online Accounts Google identity and token."""
    try:
        import gi
        gi.require_version("Gio", "2.0")
        from gi.repository import Gio, GLib

        manager = Gio.DBusObjectManagerClient.new_for_bus_sync(
            Gio.BusType.SESSION,
            Gio.DBusObjectManagerClientFlags.NONE,
            "org.gnome.OnlineAccounts",
            "/org/gnome/OnlineAccounts",
            None, None, None,
        )
        for obj in manager.get_objects():
            account = obj.get_interface("org.gnome.OnlineAccounts.Account")
            if account is None:
                continue
            provider = account.get_cached_property("ProviderType")
            if provider is None or provider.unpack() != "google":
                continue
            if obj.get_interface("org.gnome.OnlineAccounts.Tasks") is None:
                continue
            identity_value = account.get_cached_property("PresentationIdentity")
            identity = identity_value.unpack() if identity_value is not None else "Google account"
            if not with_token:
                return {"identity": identity}

            account.call_sync(
                "EnsureCredentials", None, Gio.DBusCallFlags.NONE, 30000, None
            )
            oauth = obj.get_interface("org.gnome.OnlineAccounts.OAuth2Based")
            if oauth is None:
                raise RuntimeError("Google account does not expose OAuth access")
            result = oauth.call_sync(
                "GetAccessToken", None, Gio.DBusCallFlags.NONE, 30000, None
            ).unpack()
            return {"identity": identity, "access_token": result[0]}
    except Exception as error:
        if with_token:
            raise RuntimeError(f"Could not access GNOME Online Accounts: {error}") from error
    return None


def emit(status, **extra):
    print(json.dumps({"status": status, **extra}, separators=(",", ":")))


def atomic_json(path, value, mode=0o600):
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(path.suffix + ".tmp")
    temp.write_text(json.dumps(value, indent=2), encoding="utf-8")
    os.chmod(temp, mode)
    temp.replace(path)


def credentials():
    if not CREDS_PATH.exists():
        raise RuntimeError(f"Place a Google Desktop OAuth client JSON at {CREDS_PATH}")
    raw = json.loads(CREDS_PATH.read_text(encoding="utf-8"))
    data = raw.get("installed") or raw.get("web") or raw
    if not data.get("client_id"):
        raise RuntimeError("The OAuth client JSON has no client_id")
    return data


def post_form(url, fields):
    req = urllib.request.Request(url, urllib.parse.urlencode(fields).encode(), method="POST")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    with urllib.request.urlopen(req, timeout=30) as response:
        return json.load(response)


def refresh_token(token, creds):
    if token.get("expires_at", 0) > time.time() + 90:
        return token
    if not token.get("refresh_token"):
        raise RuntimeError("Google authorization expired; connect again")
    updated = post_form(creds.get("token_uri", "https://oauth2.googleapis.com/token"), {
        "client_id": creds["client_id"],
        "client_secret": creds.get("client_secret", ""),
        "refresh_token": token["refresh_token"],
        "grant_type": "refresh_token",
    })
    token.update(updated)
    token["expires_at"] = time.time() + int(updated.get("expires_in", 3600))
    atomic_json(TOKEN_PATH, token)
    return token


def get_token():
    goa_account = goa_google_account(with_token=True)
    if goa_account:
        return goa_account
    if not TOKEN_PATH.exists():
        raise RuntimeError("Add a Google account in GNOME Online Accounts")
    return refresh_token(json.loads(TOKEN_PATH.read_text(encoding="utf-8")), credentials())


def api(method, path, token, body=None, query=None):
    url = "https://tasks.googleapis.com/tasks/v1" + path
    if query:
        url += "?" + urllib.parse.urlencode(query)
    data = None if body is None else json.dumps(body).encode()
    request = urllib.request.Request(url, data=data, method=method)
    request.add_header("Authorization", "Bearer " + token["access_token"])
    if data is not None:
        request.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            payload = response.read()
            return json.loads(payload) if payload else {}
    except urllib.error.HTTPError as error:
        detail = error.read().decode(errors="replace")
        raise RuntimeError(f"Google Tasks API {error.code}: {detail[:240]}") from error


def authorize():
    creds = credentials()
    verifier = base64.urlsafe_b64encode(secrets.token_bytes(48)).decode().rstrip("=")
    challenge = base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).decode().rstrip("=")
    state = secrets.token_urlsafe(24)
    result = {}

    class Callback(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            params = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
            result.update({key: values[0] for key, values in params.items()})
            body = b"<html><body style='font-family:sans-serif;padding:3rem'><h2>Google Tasks connected</h2><p>You can close this tab and return to Settings.</p></body></html>"
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, *_):
            pass

    with socket.socket() as probe:
        probe.bind(("127.0.0.1", 0))
        port = probe.getsockname()[1]
    redirect = f"http://127.0.0.1:{port}"
    auth_url = creds.get("auth_uri", "https://accounts.google.com/o/oauth2/auth") + "?" + urllib.parse.urlencode({
        "client_id": creds["client_id"], "redirect_uri": redirect,
        "response_type": "code", "scope": SCOPE, "access_type": "offline",
        "prompt": "consent", "state": state, "code_challenge": challenge,
        "code_challenge_method": "S256",
    })
    webbrowser.open(auth_url)
    server = http.server.HTTPServer(("127.0.0.1", port), Callback)
    server.timeout = 180
    server.handle_request()
    if result.get("state") != state or not result.get("code"):
        raise RuntimeError(result.get("error", "Authorization timed out or was cancelled"))
    token = post_form(creds.get("token_uri", "https://oauth2.googleapis.com/token"), {
        "client_id": creds["client_id"], "client_secret": creds.get("client_secret", ""),
        "code": result["code"], "code_verifier": verifier,
        "grant_type": "authorization_code", "redirect_uri": redirect,
    })
    token["expires_at"] = time.time() + int(token.get("expires_in", 3600))
    atomic_json(TOKEN_PATH, token)
    emit("connected")


def task_list_id(token):
    lists = api("GET", "/users/@me/lists", token).get("items", [])
    if not lists:
        created = api("POST", "/users/@me/lists", token, {"title": "My Tasks"})
        return created["id"]
    return lists[0]["id"]


def sync():
    token = get_token()
    list_id = task_list_id(token)
    encoded = urllib.parse.quote(list_id, safe="")
    remote = api("GET", f"/lists/{encoded}/tasks", token,
                 query={"showCompleted": "true", "showHidden": "true", "maxResults": 100}).get("items", [])
    remote_by_id = {item["id"]: item for item in remote}
    try:
        local = json.loads(TODO_PATH.read_text(encoding="utf-8")) if TODO_PATH.exists() else []
    except (json.JSONDecodeError, OSError):
        local = []
    output = []
    seen = set()
    for item in local:
        google_id = item.get("googleId")
        if item.get("_deleted"):
            if google_id and google_id in remote_by_id:
                api("DELETE", f"/lists/{encoded}/tasks/{urllib.parse.quote(google_id, safe='')}", token)
            continue
        payload = {"title": item.get("content", "Untitled task"),
                   "status": "completed" if item.get("done") else "needsAction"}
        if google_id and google_id in remote_by_id:
            if item.get("_dirty"):
                saved = api("PATCH", f"/lists/{encoded}/tasks/{urllib.parse.quote(google_id, safe='')}", token, payload)
            else:
                saved = remote_by_id[google_id]
                item["content"] = saved.get("title", item.get("content", "Untitled task"))
                item["done"] = saved.get("status") == "completed"
        else:
            saved = api("POST", f"/lists/{encoded}/tasks", token, payload)
        item["googleId"] = saved["id"]
        item.pop("_deleted", None)
        item.pop("_dirty", None)
        output.append(item)
        seen.add(saved["id"])
    for item in remote:
        if item["id"] not in seen and not item.get("deleted", False):
            output.append({"content": item.get("title", "Untitled task"),
                           "done": item.get("status") == "completed", "googleId": item["id"]})
    atomic_json(TODO_PATH, output, 0o600)
    emit("synced", count=len(output))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("status", "auth", "sync", "disconnect"))
    args = parser.parse_args()
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    if args.command == "status":
        goa_account = goa_google_account()
        if goa_account:
            emit("connected", credentials=True, source="goa", identity=goa_account["identity"])
        else:
            emit("connected" if TOKEN_PATH.exists() else "disconnected",
                 credentials=CREDS_PATH.exists(), source="legacy")
    elif args.command == "auth":
        goa_account = goa_google_account()
        if goa_account:
            emit("connected", source="goa", identity=goa_account["identity"])
        elif CREDS_PATH.exists():
            authorize()
        else:
            subprocess.Popen(["env", "XDG_CURRENT_DESKTOP=GNOME",
                              "gnome-control-center", "online-accounts"],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            emit("settings_opened", credentials=True)
    elif args.command == "sync":
        sync()
    else:
        TOKEN_PATH.unlink(missing_ok=True)
        emit("disconnected")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        emit("error", message=str(error))
        sys.exit(1)
