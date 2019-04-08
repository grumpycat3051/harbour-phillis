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
