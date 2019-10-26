import QtQuick 2.0

Item {
    id: root
    property var _delegate
    property string source
    property int fillMode: Image.Stretch

    onSourceChanged: {
        if (_delegate) {
            _delegate.source = source
        }
    }

    onFillModeChanged: {
        if (_delegate) {
            _delegate.fillMode = fillMode
        }
    }

    Component.onCompleted: {
        _delegate = _createIcon()
        _delegate.anchors.fill = root
        _delegate.source = source
        _delegate.fillMode = fillMode
    }

    function _createIcon(parent) {
        try {
            var x = Qt.createQmlObject("import Sailfish.Silica 1.0; Icon {}",
                                           root,
                                           "script");
            if (x) {
//                console.debug("Silica Icon created")
                return x
            }
        } catch (e) {
//            console.debug("exception: " + e.message)
        }

//        console.debug("failed to create Silica Icon type, falling back to theme colored QML Image")

        return Qt.createQmlObject("ThemeColoredImage {}",
                                       root,
                                       "script");
    }
}
