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
import grumpycat 1.0

Page {
    SilicaFlickable {
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: column.height

        VerticalScrollDecorator {}

        Column {
            id: column
            width: parent.width

            PageHeader {
                //% "About %1"
                title: qsTrId("about-page-header").arg(App.displayName)
            }

            Column {
                spacing: Theme.paddingLarge
                width: parent.width

                Column {
                    spacing: Theme.paddingMedium
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*x

                    Image {
                        source: "file:///usr/share/icons/hicolor/128x128/apps/harbour-phillis.png"
                        anchors.horizontalCenter: parent.horizontalCenter
                        fillMode: Image.PreserveAspectFit
                        width: Theme.iconSizeLarge
                        height: Theme.iconSizeLarge

                        MouseArea {
                            id: debugEnabler
                            property int clicks: 0
                            anchors.fill: parent

                            onClicked: {
                                timer.running = true
                                clicks = clicks + 1
                            }

                            function timerDone() {
    //                            console.debug("triggered")
                                if (clicks >= 10) {
                                    debugApp.value = true
                                }

                                clicks = 0
                            }

                            Timer {
                                id: timer
                                interval: 3000; running: false; repeat: false
                                onTriggered: debugEnabler.timerDone()
                            }
                        }
                    }

                    Label {
                        //% "%1 %2"
                        text: qsTrId("about-page-version-text").arg(App.displayName).arg(App.version)
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.highlightColor
                    }


                    Button {
                        text: "Disable debugging"
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: debugApp.value
                        onClicked: debugApp.value = false
                    }
                }

                SectionHeader {
                    //% "Description"
                    text: qsTrId("about-page-description-header")
                }

                LinkedLabel {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*x
                    //% "%1 is an unofficial Sailfish OS client for the adult content website <a href='https://www.pornhub.com/'>Pornhub</a>."
                    text: qsTrId("about-page-description-text").arg(App.displayName)
                    wrapMode: Text.WordWrap
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryHighlightColor
                    linkColor: Theme.secondaryColor
                }

                SectionHeader {
                    //% "Privacy"
                    text: qsTrId("about-privacy-header")
                }

                LinkedLabel {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*x
                    //% "This application does not collect or save any personal data aside from possibly those credentials required to sign into <a href='https://www.pornhub.com/'>Pornhub</a>."
                    text: qsTrId("about-page-privacy-text").arg(App.displayName)
                    wrapMode: Text.WordWrap
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryHighlightColor
                    linkColor: Theme.secondaryColor
                }

                SectionHeader {
                    //% "Licensing"
                    text: qsTrId("about-page-licensing-header")
                }

                LinkedLabel {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*x
                    //% "Copyright © 2019 grumpycat<br/><br/>This application is available under the MIT licence on <a href='https://github.com/grumpycat3051/harbour-phillis/'>Github</a>. %1 uses icons made by Smashicons from <a href='https://www.flaticon.com/'>flaticon</a>.<br/><br/>The content provided through %1 is the property and sole responsibility of <a href='https://www.pornhub.com/'>Pornhub</a>."
                    text: qsTrId("about-page-licensing-text").arg(App.displayName)
                    wrapMode: Text.WordWrap
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryHighlightColor
                    linkColor: Theme.secondaryColor
                }

                Item {
                    width: parent.width
                    height: Theme.paddingLarge
                }
            }
        }
    }
}

