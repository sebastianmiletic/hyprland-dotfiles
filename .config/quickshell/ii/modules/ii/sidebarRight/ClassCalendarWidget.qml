pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
    clip: true
    property date selectedDate: initialDate()
    property var selectedClasses: ClassSchedule.classesForDate(selectedDate)

    function initialDate() {
        const date = new Date()
        date.setHours(12, 0, 0, 0)
        if (date.getDay() === 6) date.setDate(date.getDate() + 2)
        else if (date.getDay() === 0) date.setDate(date.getDate() + 1)
        return date
    }

    function showDate(date) {
        const copy = new Date(date.getTime())
        copy.setHours(12, 0, 0, 0)
        root.selectedDate = copy
        root.selectedClasses = ClassSchedule.classesForDate(copy)
    }

    function moveDay(offset) {
        const date = new Date(root.selectedDate.getTime())
        date.setDate(date.getDate() + offset)
        showDate(date)
    }

    function resetDate() {
        showDate(initialDate())
    }

    Connections {
        target: ClassSchedule
        function onListChanged() { root.selectedClasses = ClassSchedule.classesForDate(root.selectedDate) }
    }

    Connections {
        target: GlobalStates
        function onSidebarRightOpenChanged() {
            if (GlobalStates.sidebarRightOpen) root.resetDate()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Rectangle {
                implicitWidth: 38; implicitHeight: 38; radius: 13
                color: Appearance.colors.colPrimaryContainer
                MaterialSymbol { anchors.centerIn: parent; text: "calendar_today"; iconSize: 20; color: Appearance.colors.colOnPrimaryContainer }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 0
                StyledText { text: Translation.tr("Classes"); color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.large; font.weight: Font.DemiBold }
                StyledText { text: Qt.formatDate(root.selectedDate, "dddd, d MMMM"); color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
            }
            Rectangle {
                implicitWidth: countLabel.implicitWidth + 18; implicitHeight: 28; radius: 14
                color: Appearance.colors.colLayer2
                StyledText { id: countLabel; anchors.centerIn: parent; text: root.selectedClasses.length; color: Appearance.colors.colOnLayer2; font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.DemiBold }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            NavButton { symbol: "chevron_left"; accessibleName: Translation.tr("Previous day"); onClicked: root.moveDay(-1) }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 34
                radius: 11
                color: Appearance.colors.colLayer2
                StyledText {
                    anchors.centerIn: parent
                    text: Qt.formatDate(root.selectedDate, "ddd, d MMM")
                    color: Appearance.colors.colOnLayer2
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.resetDate() }
            }
            NavButton { symbol: "chevron_right"; accessibleName: Translation.tr("Next day"); onClicked: root.moveDay(1) }
        }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Appearance.colors.colLayer0Border }
        StyledListView {
            id: classList
            Layout.fillWidth: true; Layout.fillHeight: true
            spacing: 8; clip: true; model: root.selectedClasses
            delegate: Rectangle {
                required property var modelData
                width: classList.width; height: 66; radius: Appearance.rounding.small
                color: Appearance.colors.colLayer2
                border.width: 1; border.color: Appearance.colors.colLayer0Border
                RowLayout {
                    anchors.fill: parent; anchors.margins: 10; spacing: 11
                    Rectangle { Layout.fillHeight: true; implicitWidth: 4; radius: 2; color: Appearance.colors.colPrimary }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 3
                        StyledText { Layout.fillWidth: true; text: modelData.title || Translation.tr("Untitled class"); elide: Text.ElideRight; color: Appearance.colors.colOnLayer2; font.pixelSize: Appearance.font.pixelSize.normal; font.weight: Font.DemiBold }
                        RowLayout {
                            spacing: 5
                            MaterialSymbol { text: "location_on"; iconSize: 14; color: Appearance.colors.colSubtext }
                            StyledText { text: modelData.room || Translation.tr("Room not set"); color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        }
                    }
                    StyledText { text: modelData.end ? `${modelData.start}–${modelData.end}` : modelData.start; color: Appearance.colors.colPrimary; font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.DemiBold }
                }
            }
            ColumnLayout {
                anchors.centerIn: parent; visible: root.selectedClasses.length === 0; spacing: 6
                MaterialSymbol { Layout.alignment: Qt.AlignHCenter; text: "event_available"; iconSize: 34; color: Appearance.colors.colSubtext }
                StyledText { Layout.alignment: Qt.AlignHCenter; text: Translation.tr("No classes this day"); color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.normal; font.weight: Font.DemiBold }
                StyledText { Layout.alignment: Qt.AlignHCenter; visible: ClassSchedule.list.length === 0; text: Translation.tr("Add your timetable in Super+I → Productivity"); color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
            }
        }
    }

    component NavButton: Rectangle {
        id: navButton
        required property string symbol
        required property string accessibleName
        signal clicked()
        implicitWidth: 38
        implicitHeight: 34
        radius: 11
        color: navMouse.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2
        Accessible.name: accessibleName
        Accessible.role: Accessible.Button
        MaterialSymbol { anchors.centerIn: parent; text: navButton.symbol; iconSize: 20; color: Appearance.colors.colOnLayer2 }
        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: navButton.clicked()
        }
    }
}
