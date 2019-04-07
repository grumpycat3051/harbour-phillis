import QtQuick 2.0
import Sailfish.Silica 1.0

Image {
    fillMode: Image.PreserveAspectFit
    property alias title: titleLabel.text
    property alias titleFontPixelSize: titleLabel.font.pixelSize
    property real overlayOpacity: 0.68
    property real topFrameHeight: titleLabel.height
    property real bottomFrameHeight: bottomFrameContent ? bottomFrameContent.height : 0
    property Item bottomFrameContent


    Rectangle {
        id: topFrame
        anchors.top: parent.top
        width: parent.width
        height: topFrameHeight
        color: "black"
        opacity: overlayOpacity
        layer.enabled: true

        Label {
            id: titleLabel
            x: Theme.paddingSmall
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 2*x
            truncationMode: TruncationMode.Fade
            font.bold: true
        }
    }

    Rectangle {
        id: bottomFrame
        anchors.bottom: parent.bottom
        width: parent.width
        height: bottomFrameHeight
        color: "black"
        opacity: overlayOpacity
        layer.enabled: true
    }

    onBottomFrameContentChanged: {
        if (bottomFrameContent) {
            bottomFrameContent.parent = bottomFrame
        }
    }
}
