pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import Quickshell;
import Quickshell.Io;
import QtQuick;

/**
 * Simple to-do list manager.
 * Each item is an object with "content" and "done" properties.
 */
Singleton {
    id: root
    property var filePath: Directories.todoPath
    property var list: []
    
    function addItem(item) {
        list.push(item)
        // Reassign to trigger onListChanged
        root.list = list.slice(0)
        todoFileView.setText(JSON.stringify(root.list))
        if (GoogleTasks.connected) googleSyncDelay.restart()
    }

    function addTask(desc) {
        const item = {
            "content": desc,
            "done": false,
            "_dirty": true,
        }
        addItem(item)
    }

    function markDone(index) {
        if (index >= 0 && index < list.length) {
            list[index].done = true
            list[index]._dirty = true
            // Reassign to trigger onListChanged
            root.list = list.slice(0)
            todoFileView.setText(JSON.stringify(root.list))
            if (GoogleTasks.connected) googleSyncDelay.restart()
        }
    }

    function markUnfinished(index) {
        if (index >= 0 && index < list.length) {
            list[index].done = false
            list[index]._dirty = true
            // Reassign to trigger onListChanged
            root.list = list.slice(0)
            todoFileView.setText(JSON.stringify(root.list))
            if (GoogleTasks.connected) googleSyncDelay.restart()
        }
    }

    function deleteItem(index) {
        if (index >= 0 && index < list.length) {
            if (GoogleTasks.connected && list[index].googleId) {
                list[index]._deleted = true
            } else {
                list.splice(index, 1)
            }
            // Reassign to trigger onListChanged
            root.list = list.slice(0)
            todoFileView.setText(JSON.stringify(root.list))
            if (GoogleTasks.connected) googleSyncDelay.restart()
        }
    }

    function refresh() {
        todoFileView.reload()
    }

    Component.onCompleted: {
        refresh()
    }

    Timer {
        id: googleSyncDelay
        interval: 700
        repeat: false
        onTriggered: GoogleTasks.sync()
    }

    FileView {
        id: todoFileView
        path: Qt.resolvedUrl(root.filePath)
        onLoaded: {
            const fileContents = todoFileView.text()
            const parsed = JSON.parse(fileContents)
            root.list = Array.isArray(parsed) ? parsed : []
            console.log("[To Do] File loaded")
        }
        onLoadFailed: (error) => {
            if(error == FileViewError.FileNotFound) {
                console.log("[To Do] File not found, creating new file.")
                root.list = []
                todoFileView.setText(JSON.stringify(root.list))
            } else {
                console.log("[To Do] Error loading file: " + error)
            }
        }
    }
}
