/* The MIT License (MIT)
 *
 * Copyright (c) 2019, 2020 grumpycat <grumpycat3051@protonmail.com>
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
    allowedOrientations: defaultAllowedOrientations
    backNavigation: false
    SilicaFlickable {
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: column.height

        VerticalScrollDecorator {}

        Column {
            id: column
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2*Theme.paddingMedium

            Item {
                width: parent.width
                height: Theme.fontSizeHuge
            }

            Column {
                width: parent.width

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    //% "Adult Content Disclaimer"
                    text: qsTrId("ph-disclaimer-page-title")
                    font {
                        pixelSize: Theme.fontSizeExtraLarge
                        family: Theme.fontFamilyHeading
                    }
                    color: Theme.secondaryHighlightColor
                }

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    //% "The content provided through this app is designed for ADULTS only and may include pictures and materials that some viewers may find offensive. If you are under the age of 18, if such material offends you or if it is illegal to view such material in your community please exit the site. The following terms and conditions apply to this site. Use of the site will constitute your agreement to the following terms and conditions:"
                    text: qsTrId("ph-disclaimer-page-text1")
                    font {
                        pixelSize: Theme.fontSizeSmall
                    }
                    color: Theme.highlightColor
                    opacity: 0.4
                }

                Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    //% "1.) I am 18 years of age or older<br/>2.) I accept all responsibility for my own actions; and<br/>3.) I agree that I am legally bound to these Terms and Conditions"
                    text: qsTrId("ph-disclaimer-page-text2")
                    font {
                        pixelSize: Theme.fontSizeMedium
                        bold: true

                    }
                    color: Theme.highlightColor
                    opacity: 0.4
                }
            }

            ButtonLayout {
                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    //% "Accept"
                    text: qsTrId("ph-disclaimer-page-accept-button")
                    onClicked: disclaimerAccepted.value = true
                }
            }

            Item {
                width: parent.width
                height: Theme.paddingLarge
            }
        }
    }
}


