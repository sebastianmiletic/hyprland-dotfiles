pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool connected: false
    property bool credentialsReady: false
    property bool permissionRequired: false
    property bool busy: false
    property string statusText: "Not connected"
    property string helperPath: Quickshell.shellPath("scripts/google-tasks.py")
    property string pendingAction: "status"

    function run(action) {
        if (taskProcess.running) return
        pendingAction = action
        busy = true
        taskProcess.command = [helperPath, action]
        taskProcess.running = true
    }

    function checkStatus() { run("status") }
    function connectAccount() { run("auth") }
    function sync() { run("sync") }
    function disconnectAccount() { run("disconnect") }
    function importCredentials() {
        if (busy) return
        busy = true
        credentialPicker.running = true
    }

    Component.onCompleted: checkStatus()

    Process {
        id: taskProcess
        stdout: StdioCollector { id: outputCollector }
        onExited: exitCode => {
            root.busy = false
            try {
                const result = JSON.parse(outputCollector.text.trim())
                root.credentialsReady = result.credentials ?? root.credentialsReady
                root.connected = result.status === "connected" || result.status === "synced"
                root.permissionRequired = result.status === "permission_required"
                if (result.status === "synced") {
                    root.statusText = `Synced ${result.count} tasks just now`
                    Todo.refresh()
                } else if (result.status === "connected") {
                    root.statusText = result.identity ? `Connected as ${result.identity}` : "Google Tasks connected"
                    if (root.pendingAction === "auth") Qt.callLater(() => root.sync())
                } else if (result.status === "credentials_imported") {
                    root.credentialsReady = true
                    root.statusText = "OAuth JSON imported; opening Google consent"
                    Qt.callLater(() => root.connectAccount())
                } else if (result.status === "setup_opened") {
                    root.statusText = "Create a Desktop OAuth client, then import its JSON"
                } else if (result.status === "permission_required") {
                    root.statusText = result.message || "Google Tasks permission required"
                } else if (result.status === "disconnected") {
                    root.statusText = "Add Google in Online Accounts"
                } else {
                    root.statusText = result.message || "Google Tasks error"
                }
            } catch (error) {
                root.statusText = exitCode === 0 ? "Google Tasks ready" : "Google Tasks command failed"
            }
        }
    }

    Process {
        id: credentialPicker
        command: ["zenity", "--file-selection", "--title=Import Google Desktop OAuth JSON", "--file-filter=JSON files | *.json"]
        stdout: StdioCollector { id: credentialPickerOutput }
        onExited: exitCode => {
            const path = credentialPickerOutput.text.trim()
            if (exitCode !== 0 || !path) {
                root.busy = false
                root.statusText = "OAuth JSON import cancelled"
                return
            }
            root.pendingAction = "install-credentials"
            taskProcess.command = [root.helperPath, "install-credentials", path]
            taskProcess.running = true
        }
    }
}
