import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.sidebarRight.todo

Rectangle {
    id: root
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
    clip: true
    implicitHeight: 330

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8
            MaterialSymbol { text: "task_alt"; iconSize: 20; color: Appearance.colors.colPrimary }
            StyledText { Layout.fillWidth: true; text: Translation.tr("Google Tasks"); color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.large; font.weight: Font.DemiBold }
            StyledText {
                visible: GoogleTasks.connected
                text: GoogleTasks.statusText
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
                elide: Text.ElideRight
                Layout.maximumWidth: 145
            }
            RippleButton {
                implicitWidth: 34; implicitHeight: 34; buttonRadius: 17
                enabled: !GoogleTasks.busy
                onClicked: GoogleTasks.connected ? GoogleTasks.sync() : (GoogleTasks.credentialsReady ? GoogleTasks.connectAccount() : GoogleTasks.importCredentials())
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: GoogleTasks.connected ? "sync" : "account_circle"
                    iconSize: 18
                    color: Appearance.colors.colPrimary
                    RotationAnimation on rotation { running: GoogleTasks.busy; from: 0; to: 360; duration: 900; loops: Animation.Infinite }
                }
                StyledToolTip { text: GoogleTasks.connected ? Translation.tr("Sync Google Tasks") : (GoogleTasks.credentialsReady ? Translation.tr("Connect Google Tasks") : Translation.tr("Import OAuth JSON")) }
            }
        }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Appearance.colors.colLayer0Border }
        TodoWidget { Layout.fillWidth: true; Layout.fillHeight: true }
    }
}
