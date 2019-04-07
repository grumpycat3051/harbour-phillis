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
import ".."

CoverBackground {
    id: coverPage

    property bool _pausedVideo

    Image {
        anchors.fill: parent
        source: "file:///usr/share/harbour-phillis/media/cover.png"
        fillMode: Image.PreserveAspectCrop
    }

    onStatusChanged: {
//        console.debug("cover page status=" + status)
        switch (status) {
        case PageStatus.Activating:
            // NOTE: the cover page will be active if the app menu is open
            // NOTE: the cover page will go though an activating->active->deactivating->inactive
            //       cycle if the device comes out of lock
            //sqlModel.select = ""
            if (settingPlaybackPauseInCoverMode.value) {
                if (window.videoPlayerPage) {
                    _pausedVideo = true
                    window.videoPlayerPage.pause()
                }
            }

            if (window.restrictAccess && !pageStack.currentPage.isLockScreenPage) {
                pageStack.push(Qt.resolvedUrl("../pages/LockScreenPage.qml"), {}, PageStackAction.Immediate)
            }
            break
        case PageStatus.Deactivating:
            if (_pausedVideo) {
                _pausedVideo = false
                if (window.videoPlayerPage) {
                    window.videoPlayerPage.resume()
                }
            }
            break
        }
    }
}
