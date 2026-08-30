pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: root
    forceWidth: true
    property var days: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    ContentSection {
        icon: "school"
        title: Translation.tr("Class timetable")

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Import your school or university iCalendar file. Recurring classes, times and rooms will appear automatically in the Super+N sidebar.")
            color: Appearance.colors.colSubtext
            wrapMode: Text.WordWrap
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 76
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Rectangle {
                    implicitWidth: 46; implicitHeight: 46; radius: 15
                    color: Appearance.colors.colPrimaryContainer
                    MaterialSymbol { anchors.centerIn: parent; text: "calendar_add_on"; iconSize: 24; color: Appearance.colors.colOnPrimaryContainer }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    StyledText { text: ClassSchedule.list.length > 0 ? Translation.tr("Timetable ready") : Translation.tr("Import an ICS timetable"); color: Appearance.colors.colOnLayer2; font.pixelSize: Appearance.font.pixelSize.large; font.weight: Font.DemiBold }
                    StyledText { Layout.fillWidth: true; text: ClassSchedule.importStatus; color: Appearance.colors.colSubtext; elide: Text.ElideMiddle }
                    StyledText { Layout.fillWidth: true; visible: ClassSchedule.importedSource.length > 0; text: ClassSchedule.importedSource; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller; elide: Text.ElideMiddle }
                }
                DialogButton {
                    visible: ClassSchedule.list.length > 0
                    buttonText: Translation.tr("Clear")
                    onClicked: ClassSchedule.clear()
                }
                DialogButton {
                    enabled: !ClassSchedule.importing
                    buttonText: ClassSchedule.importing ? Translation.tr("Importing…") : (ClassSchedule.list.length > 0 ? Translation.tr("Replace ICS") : Translation.tr("Choose ICS"))
                    onClicked: ClassSchedule.importIcs()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Math.max(120, scheduleColumn.implicitHeight + 16)
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            ColumnLayout {
                id: scheduleColumn
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                anchors.margins: 8
                spacing: 5

                Repeater {
                    model: ClassSchedule.list.slice().sort((a, b) => Number(a.day) - Number(b.day) || (a.start || "").localeCompare(b.start || ""))
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 54
                        radius: Appearance.rounding.small
                        color: Appearance.colors.colLayer2
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 10; spacing: 12
                            StyledText { Layout.preferredWidth: 82; text: root.days[Number(modelData.day)].slice(0, 3); color: Appearance.colors.colPrimary; font.weight: Font.DemiBold }
                            StyledText { Layout.fillWidth: true; text: modelData.title; color: Appearance.colors.colOnLayer2; font.weight: Font.DemiBold; elide: Text.ElideRight }
                            StyledText { text: modelData.room || Translation.tr("No room"); color: Appearance.colors.colSubtext }
                            StyledText { Layout.preferredWidth: 105; text: modelData.end ? `${modelData.start}–${modelData.end}` : modelData.start; color: Appearance.colors.colOnLayer2 }
                            RippleButton {
                                implicitWidth: 32; implicitHeight: 32; buttonRadius: 16
                                onClicked: ClassSchedule.deleteClass(modelData.id)
                                contentItem: MaterialSymbol { anchors.centerIn: parent; text: "delete"; iconSize: 17; color: Appearance.colors.colError }
                            }
                        }
                    }
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 28
                    visible: ClassSchedule.list.length === 0
                    text: Translation.tr("Your timetable is empty — choose an .ics file above.")
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }

    ContentSection {
        icon: "task_alt"
        title: Translation.tr("Google Tasks")

        RowLayout {
            Layout.fillWidth: true
            spacing: 14
            Rectangle {
                implicitWidth: 48; implicitHeight: 48; radius: 16
                color: Appearance.colors.colPrimaryContainer
                MaterialSymbol { anchors.centerIn: parent; text: "task_alt"; iconSize: 25; color: Appearance.colors.colOnPrimaryContainer }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                StyledText { text: GoogleTasks.connected ? Translation.tr("Connected") : Translation.tr("Connect Google Tasks"); color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.large; font.weight: Font.DemiBold }
                StyledText { Layout.fillWidth: true; text: GoogleTasks.statusText; color: Appearance.colors.colSubtext; elide: Text.ElideRight }
            }
            DialogButton {
                visible: !GoogleTasks.connected
                buttonText: GoogleTasks.credentialsReady ? Translation.tr("Connect") : Translation.tr("Setup guide")
                onClicked: GoogleTasks.connectAccount()
            }
            DialogButton {
                visible: GoogleTasks.connected
                enabled: !GoogleTasks.busy
                buttonText: GoogleTasks.busy ? Translation.tr("Syncing…") : Translation.tr("Sync now")
                onClicked: GoogleTasks.sync()
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Your Google account is present, but GNOME Online Accounts does not grant the Tasks permission. Enable the Google Tasks API, create a Desktop OAuth client, download its JSON, and import it here. The sidebar then syncs additions, completions, and deletions directly with Google Tasks.")
            color: Appearance.colors.colSubtext
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            DialogButton {
                buttonText: Translation.tr("Import OAuth JSON")
                enabled: !GoogleTasks.busy
                onClicked: GoogleTasks.importCredentials()
            }
            DialogButton {
                buttonText: Translation.tr("Recheck")
                enabled: !GoogleTasks.busy
                onClicked: GoogleTasks.checkStatus()
            }
            Item { Layout.fillWidth: true }
            DialogButton {
                visible: !GoogleTasks.connected
                buttonText: Translation.tr("Open setup guide")
                onClicked: Quickshell.execDetached(["xdg-open", "https://developers.google.com/workspace/tasks/quickstart/python#set_up_your_environment"])
            }
        }

    }
}
