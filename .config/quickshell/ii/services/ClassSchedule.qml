pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Singleton {
    id: root

    property var list: []
    readonly property int today: new Date().getDay()
    property bool importing: false
    property string importStatus: list.length > 0 ? `${list.length} timetable entries loaded` : "No timetable imported"
    property string importedSource: list.length > 0 ? (list[0].source || "") : ""

    function save() {
        scheduleFile.setText(JSON.stringify(root.list, null, 2))
    }

    function addClass(title, room, day, startTime, endTime) {
        root.list = root.list.concat([{
            "id": Date.now().toString(),
            "title": title.trim(),
            "room": room.trim(),
            "day": Number(day),
            "start": startTime.trim(),
            "end": endTime.trim()
        }])
        save()
    }

    function deleteClass(id) {
        root.list = root.list.filter(item => item.id !== id)
        save()
    }

    function clear() {
        root.list = []
        root.importedSource = ""
        root.importStatus = "Timetable cleared"
        save()
    }

    function importIcs() {
        if (root.importing) return
        root.importing = true
        filePicker.running = true
    }

    function classesForDate(date) {
        const dateString = Qt.formatDate(date, "yyyy-MM-dd")
        const day = date.getDay()
        return root.list.filter(item => {
            if (Number(item.day) !== Number(day)) return false
            if (item.singleDate && item.singleDate !== dateString) return false
            if (item.validFrom && dateString < item.validFrom) return false
            if (item.validUntil && dateString > item.validUntil) return false
            return true
        }).sort((a, b) =>
            (a.start || "").localeCompare(b.start || ""))
    }

    function classesForDay(day) {
        const date = new Date()
        date.setDate(date.getDate() + Number(day) - date.getDay())
        return classesForDate(date)
    }

    function refresh() {
        scheduleFile.reload()
    }

    Component.onCompleted: refresh()

    Process {
        id: filePicker
        command: ["zenity", "--file-selection", "--title=Import class timetable", "--file-filter=iCalendar files | *.ics *.ical", "--file-filter=All files | *"]
        stdout: StdioCollector { id: pickerOutput }
        onExited: exitCode => {
            const path = pickerOutput.text.trim()
            if (exitCode !== 0 || !path) {
                root.importing = false
                root.importStatus = "Import cancelled"
                return
            }
            icsImporter.command = [Quickshell.shellPath("scripts/import-ics.py"), path, Directories.classSchedulePath]
            icsImporter.running = true
        }
    }

    Process {
        id: icsImporter
        stdout: StdioCollector { id: importerOutput }
        onExited: exitCode => {
            root.importing = false
            try {
                const result = JSON.parse(importerOutput.text.trim())
                root.importStatus = result.status === "imported" ? `Imported ${result.count} class entries` : (result.message || "Import failed")
                if (result.status === "imported") {
                    root.importedSource = result.source
                    root.refresh()
                }
            } catch (error) {
                root.importStatus = exitCode === 0 ? "Timetable imported" : "Import failed"
                if (exitCode === 0) root.refresh()
            }
        }
    }

    FileView {
        id: scheduleFile
        path: Qt.resolvedUrl(Directories.classSchedulePath)
        onLoaded: {
            try {
                const parsed = JSON.parse(scheduleFile.text())
                root.list = Array.isArray(parsed) ? parsed : []
            } catch (error) {
                console.warn("[ClassSchedule] Invalid schedule file:", error)
                root.list = []
            }
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.list = []
                root.save()
            }
        }
    }
}
