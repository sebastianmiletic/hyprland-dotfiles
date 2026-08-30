import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

WindowDialog {
    id: root
    backgroundHeight: 600

    WindowDialogTitle {
        text: Translation.tr("Bluetooth devices")
    }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 94
        radius: Appearance.rounding.small
        color: Appearance.colors.colLayer2

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 9
            spacing: 7

            RowLayout {
                Layout.fillWidth: true
                spacing: 9
                Rectangle {
                    implicitWidth: 34; implicitHeight: 34; radius: 12
                    color: BluetoothStatus.enabled ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer3
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: BluetoothStatus.connected ? "bluetooth_connected" : "bluetooth"
                        iconSize: 19
                        color: BluetoothStatus.enabled ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    StyledText {
                        text: BluetoothStatus.connected ? Translation.tr("Connected") : (BluetoothStatus.enabled ? Translation.tr("Ready to connect") : Translation.tr("Bluetooth is off"))
                        color: Appearance.colors.colOnLayer2
                        font.weight: Font.DemiBold
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: BluetoothStatus.activeDeviceCount > 0 ? Translation.tr("%1 active device(s)").arg(BluetoothStatus.activeDeviceCount) : Translation.tr("Connected devices appear first")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        elide: Text.ElideRight
                    }
                }
                RippleButton {
                    implicitWidth: 36; implicitHeight: 36; buttonRadius: 18
                    toggled: BluetoothStatus.enabled
                    onClicked: Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                    contentItem: MaterialSymbol { anchors.centerIn: parent; text: BluetoothStatus.enabled ? "toggle_on" : "toggle_off"; iconSize: 25; color: BluetoothStatus.enabled ? Appearance.colors.colPrimary : Appearance.colors.colSubtext }
                    StyledToolTip { text: BluetoothStatus.enabled ? Translation.tr("Turn Bluetooth off") : Translation.tr("Turn Bluetooth on") }
                }
            }
            DialogButton {
                Layout.fillWidth: true
                enabled: BluetoothStatus.enabled
                buttonText: Bluetooth.defaultAdapter?.discovering ? Translation.tr("Stop scanning") : Translation.tr("Scan for devices")
                onClicked: Bluetooth.defaultAdapter.discovering = !Bluetooth.defaultAdapter.discovering
            }
        }
    }
    WindowDialogSeparator {}
    StyledListView {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.topMargin: -8
        Layout.bottomMargin: -16
        Layout.leftMargin: -Appearance.rounding.large
        Layout.rightMargin: -Appearance.rounding.large

        clip: true
        spacing: 0
        animateAppearance: false

        model: ScriptModel {
            values: BluetoothStatus.friendlyDeviceList
        }
        delegate: BluetoothDeviceItem {
            required property BluetoothDevice modelData
            device: modelData
            anchors {
                left: parent?.left
                right: parent?.right
            }
        }
    }
    WindowDialogSeparator {}
    WindowDialogButtonRow {
        DialogButton {
            buttonText: Translation.tr("Details")
            onClicked: {
                Quickshell.execDetached(["bash", "-c", `${Config.options.apps.bluetooth}`]);
                GlobalStates.sidebarRightOpen = false;
            }
        }

        Item {
            Layout.fillWidth: true
        }

        DialogButton {
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
        }
    }
}
