import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

MouseArea {
    id: root
    required property var fileModelData
    property bool isDirectory: fileModelData.fileIsDir
    property bool useThumbnail: Images.isValidImageByName(fileModelData.fileName)
    property bool showLabel: true
    property bool selected: false
    property bool showFavoriteButton: true

    property alias colBackground: background.color
    property alias colText: wallpaperItemName.color
    property alias radius: background.radius
    property alias margins: background.anchors.margins
    property alias padding: wallpaperItemColumnLayout.anchors.margins
    margins: Appearance.sizes.wallpaperSelectorItemMargins
    padding: Appearance.sizes.wallpaperSelectorItemPadding

    signal activated()

    hoverEnabled: true
    onClicked: root.activated()

    Rectangle {
        id: background
        anchors.fill: parent
        radius: Appearance.rounding.normal
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        ColumnLayout {
            id: wallpaperItemColumnLayout
            anchors.fill: parent
            spacing: 4

            Item {
                id: wallpaperItemImageContainer
                Layout.fillHeight: true
                Layout.fillWidth: true

                Loader {
                    id: thumbnailShadowLoader
                    active: thumbnailImageLoader.active && thumbnailImageLoader.item?.status === Image.Ready
                    anchors.fill: thumbnailImageLoader
                    sourceComponent: StyledRectangularShadow {
                        target: thumbnailImageLoader
                        anchors.fill: undefined
                        radius: Appearance.rounding.small
                    }
                }

                RippleButton {
                    visible: root.showFavoriteButton && root.useThumbnail
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 9
                    width: 32
                    height: 32
                    z: 30
                    buttonRadius: 16
                    colBackground: Qt.rgba(0.04, 0.04, 0.05, 0.72)
                    onClicked: Wallpapers.toggleFavorite(root.fileModelData.filePath)

                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: Wallpapers.isFavorite(root.fileModelData.filePath) ? "favorite" : "favorite_border"
                        iconSize: 18
                        color: Wallpapers.isFavorite(root.fileModelData.filePath)
                            ? "white"
                            : "#A6FFFFFF"
                    }

                    StyledToolTip {
                        text: Wallpapers.isFavorite(root.fileModelData.filePath)
                            ? Translation.tr("Remove favorite")
                            : Translation.tr("Add favorite")
                    }
                }

                Loader {
                    id: thumbnailImageLoader
                    anchors.fill: parent
                    active: root.useThumbnail
                    sourceComponent: ThumbnailImage {
                        id: thumbnailImage
                        property bool usingFallback: false
                        property bool usingOriginal: false

                        function loadTier(tier) {
                            usingOriginal = false
                            source = ""
                            thumbnailSizeName = tier
                            Qt.callLater(() => { source = thumbnailPath })
                        }
                        generateThumbnail: false
                        // The gallery service generates this cache tier in bulk. Keeping the
                        // tier explicit also avoids a sourceSize <-> thumbnail path loop.
                        thumbnailSizeName: "xx-large"
                        sourcePath: fileModelData.filePath
                        // Wallpapers.load() generates this cache during shell
                        // startup; the persistent selector also warms Qt's
                        // image cache before the user opens the gallery.
                        source: thumbnailPath

                        cache: true
                        mipmap: true
                        fillMode: Image.PreserveAspectCrop
                        clip: true

                        onStatusChanged: {
                            // The 1024px cache is generated quietly after startup.
                            // Keep the previous 512px preview visible until each new
                            // file is ready instead of showing an empty/loading card.
                            if (status === Image.Error && thumbnailSizeName === "xx-large") {
                                usingFallback = true
                                loadTier("x-large")
                            } else if (status === Image.Error && thumbnailSizeName === "x-large") {
                                // Unsupported thumbnail formats still get a
                                // preview by decoding the original on demand.
                                usingFallback = true
                                usingOriginal = true
                                source = Qt.resolvedUrl(sourcePath)
                            }
                        }

                        Timer {
                            // A newly imported pack may be warming while the
                            // selector is open. Retry only visible/error cards
                            // so each preview appears as soon as its cache file
                            // lands, without a loading spinner or shell reload.
                            interval: 1600
                            repeat: true
                            running: thumbnailImage.status === Image.Error && !thumbnailImage.usingOriginal
                            onTriggered: thumbnailImage.loadTier("xx-large")
                        }

                        Connections {
                            target: Wallpapers
                            function onThumbnailGenerated(directory) {
                                if (FileUtils.parentDirectory(thumbnailImage.sourcePath) !== FileUtils.trimFileProtocol(directory)) return;
                                if (thumbnailImage.usingFallback) {
                                    thumbnailImage.usingFallback = false
                                    thumbnailImage.loadTier("xx-large")
                                }
                            }
                            function onThumbnailGeneratedFile(filePath) {
                                if (Qt.resolvedUrl(thumbnailImage.sourcePath) !== Qt.resolvedUrl(filePath)) return;
                                thumbnailImage.usingFallback = false
                                thumbnailImage.loadTier("xx-large")
                            }
                        }

                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: wallpaperItemImageContainer.width
                                height: wallpaperItemImageContainer.height
                                radius: Appearance.rounding.small
                            }
                        }
                    }
                }

                Loader {
                    id: iconLoader
                    active: !root.useThumbnail
                    anchors.fill: parent
                    sourceComponent: DirectoryIcon {
                        fileModelData: root.fileModelData
                    }
                }
            }

            StyledText {
                id: wallpaperItemName
                visible: root.showLabel
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10

                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.smaller
                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
                text: fileModelData.fileName
            }
        }

        // Draw above the image so keyboard selection remains unmistakable on
        // bright and dark wallpapers alike.
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: background.radius
            border.width: root.selected ? 3 : 0
            border.color: Appearance.colors.colPrimary
            z: 10

            Behavior on border.width {
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
