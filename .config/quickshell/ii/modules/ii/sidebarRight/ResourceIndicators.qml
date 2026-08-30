import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: Appearance.colors.colLayer1
    border.width: 1
    border.color: Appearance.colors.colLayer0Border
    radius: Appearance.rounding.normal

    RowLayout {
        anchors.fill: parent
        anchors.margins: 7
        spacing: 6

        ResourceMeter {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            icon: "memory"
            label: Translation.tr("CPU")
            value: ResourceUsage.cpuUsage
        }
        ResourceMeter {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            icon: "memory_alt"
            label: Translation.tr("RAM")
            value: ResourceUsage.memoryUsedPercentage
        }
        ResourceMeter {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            icon: "hard_drive"
            label: Translation.tr("Disk")
            value: ResourceUsage.storageUsedPercentage
        }
    }

    component ResourceMeter: Rectangle {
        required property string icon
        required property string label
        required property real value
        color: Appearance.colors.colLayer2
        radius: Appearance.rounding.small

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: 19
                spacing: 4
                MaterialSymbol {
                    text: parent.parent.parent.icon
                    iconSize: 15
                    color: Appearance.colors.colPrimary
                    Layout.alignment: Qt.AlignVCenter
                }
                StyledText {
                    text: parent.parent.parent.label
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    Layout.alignment: Qt.AlignVCenter
                    verticalAlignment: Text.AlignVCenter
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    text: `${Math.round(Math.max(0, Math.min(1, parent.parent.parent.value)) * 100)}%`
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                    Layout.alignment: Qt.AlignVCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 3
                radius: 2
                color: Appearance.colors.colLayer0
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, rootMeter.value))
                    height: parent.height
                    radius: parent.radius
                    color: Appearance.colors.colPrimary
                    Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                }
            }
        }

        // A stable id for bindings inside the nested progress rectangle.
        id: rootMeter
    }
}
