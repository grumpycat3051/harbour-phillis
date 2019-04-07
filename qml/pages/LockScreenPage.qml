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


Page {
    readonly property bool isLockScreenPage: true
    backNavigation: false

    SilicaFlickable {
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: parent.height

        Column {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2*Theme.paddingMedium

            Column {
                width: parent.width
                spacing: Theme.paddingLarge

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: settingAccessLockscreenText.value
                    font {
                        pixelSize: Theme.fontSizeExtraLarge
                        family: Theme.fontFamilyHeading
                    }
                    color: Theme.secondaryHighlightColor
                }

                PasswordField {
                    width: parent.width
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    EnterKey.iconSource: "image://theme/icon-m-enter-close"
                    //% "PIN"
                    placeholderText: qsTrId("lock-screen-page-pin-placeholder")
                    onTextChanged: {
                        if (text === window.pin) {
                            pageStack.pop()
                        }
                    }

                    focus: true
                }
            }
        }
    }
}


