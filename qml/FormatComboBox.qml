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
import "."


ComboBox {
    id: root

    property int format: Constants.formatUnknown
    currentIndex: -1
    //% "Format"
    label: qsTrId("format-combobox-format-label")

    menu: ContextMenu {
        id: menu
        MenuItem {
            //% "best quality (largest)"
            text: qsTrId("format-combobox-format-best")
        }
        MenuItem {
            //% "worst quality (smallest)"
            text: qsTrId("format-combobox-format-worst")
        }
        MenuItem { text: "1080" }
        MenuItem { text: "720" }
        MenuItem { text: "480" }
        MenuItem { text: "240" }
    }

    onCurrentIndexChanged: {
//        console.debug("onCurrentIndexChanged " + currentIndex)
        switch (currentIndex) {
        case 0:
            format = Constants.formatBest
            break
        case 1:
            format = Constants.formatWorst
            break
        case 2:
            format = Constants.format1080
            break
        case 3:
            format = Constants.format720
            break
        case 4:
            format = Constants.format480
            break
        case 5:
            format = Constants.format240
            break
        default:
            format = Constants.formatUnknown
            break
        }
    }

    function _propagateFormat() {
        switch (format) {
        case Constants.formatBest:
            currentIndex = 0
            break
        case Constants.formatWorst:
            currentIndex = 1
            break
        case Constants.format1080:
            currentIndex = 2
            break
        case Constants.format720:
            currentIndex = 3
            break
        case Constants.format480:
            currentIndex = 4
            break
        case Constants.format240:
            currentIndex = 5
            break
        default:
            currentIndex = -1
            break
        }
    }

    onFormatChanged: _propagateFormat()
    Component.onCompleted: _propagateFormat()
}
