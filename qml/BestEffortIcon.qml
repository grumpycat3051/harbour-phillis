/* The MIT License (MIT)
 *
 * Copyright (c) 2019 grumpycat <grumpycat3051@protonmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

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

    function _createIcon() {
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
