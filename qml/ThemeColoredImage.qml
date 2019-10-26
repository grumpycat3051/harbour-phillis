import QtQuick 2.0
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0

Item {
    property alias source: image.source
    property alias fillMode: image.fillMode

    Image {
        id: image
        anchors.fill: parent
        visible: false
    }

    ColorOverlay {
        anchors.fill: image
        source: image
        color: Theme.primaryColor
    }
}
