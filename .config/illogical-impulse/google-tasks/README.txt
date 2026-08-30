Google Tasks connection for the Quickshell sidebar

GNOME Online Accounts currently does not grant the Google Tasks scope, so the
sidebar uses a dedicated Desktop OAuth client for secure API access.

1. Open https://console.cloud.google.com/
2. Create or select a project and enable the Google Tasks API.
3. Configure the OAuth consent screen for your Google account.
4. Create an OAuth client with application type "Desktop app".
5. Download its JSON.
6. Open Super+I > Productivity, choose Import OAuth JSON, then Connect.

The token is saved locally as token.json with user-only permissions.
Do not share client_secret.json or token.json.
