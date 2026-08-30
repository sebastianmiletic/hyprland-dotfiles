pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool connected: false
    property bool credentialsReady: false
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
                if (result.status === "synced") {
                    root.statusText = `Synced ${result.count} tasks just now`
                    Todo.refresh()
                } else if (result.status === "connected") {
                    root.statusText = result.identity ? `Connected as ${result.identity}` : "Google Tasks connected"
                    if (root.pendingAction === "auth") Qt.callLater(() => root.sync())
                } else if (result.status === "settings_opened") {
                    root.statusText = "Add Google, enable Tasks, then recheck"
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
}
