Google Tasks connection for the Quickshell sidebar

Recommended: add Google in GNOME Settings > Online Accounts and enable Tasks.
The sidebar uses that account directly; no developer credentials are required.

Legacy standalone OAuth option:

1. Open https://console.cloud.google.com/
2. Create or select a project and enable the Google Tasks API.
3. Configure the OAuth consent screen for your Google account.
4. Create an OAuth client with application type "Desktop app".
5. Download its JSON and save it in this folder as client_secret.json.
6. Open Super+I > Productivity, choose Recheck setup, then Connect.

The token is saved locally as token.json with user-only permissions.
Do not share client_secret.json or token.json.
