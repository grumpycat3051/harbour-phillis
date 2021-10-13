/* The MIT License (MIT)
 *
 * Copyright (c) 2019-2021 grumpycat <grumpycat3051@protonmail.com>
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
import QtMultimedia 5.0
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0
import grumpycat 1.0
import ".."
import "../MiniJS.js" as MiniJS
import "../StateMachine.js" as Stm

Page {
    id: page
    property string videoUrl
    property string videoId
    property string videoTitle

    // Pornhub has fixed video resolutions that are always wider than high.
    // Thus we can simply fix the allowed orientations to landscape modes.
    allowedOrientations: Orientation.Landscape | Orientation.LandscapeInverted
    //allowedOrientations: defaultAllowedOrientations
    backNavigation: controlPanel.open
    readonly property int playbackOffset: streamPositonS
    readonly property int streamPositonS: Math.floor(mediaplayer.position / 1000)
    readonly property int streamDurationS: Math.ceil(mediaplayer.duration / 1000)
    property bool _forceBusyIndicator: false
    property bool _paused: false
    property int _pauseCount: 0
    property int _openCount: 0
    property bool _pauseDueToStall: false
    property bool _clickedToOpen: false
    readonly property bool isPlaying: mediaplayer.playbackState === MediaPlayer.PlayingState
    property var _formats: []
    property bool _isFavorite: false
    property int _action: -1
    property string _ratingToken

    readonly property int actionVoteUp: 0
    readonly property int actionVoteDown: 1
    readonly property int actionToggleFavorite: 2
    readonly property int actionFetchVideoUrls: 3

    property string _modelUrl
    property string _modelName
    property int _upVotes: -1
    property int _downVotes: -1
    property var _categories: []
    property var _pornstars: []
    property var _tags: []
    property var _displayBlanking
    property int _networkErrorRetryCount: 0
    property var _stateMachines: []
    readonly property bool _mediaPlayerVideoLoading:
        mediaplayer.error === MediaPlayer.NoError
        && (mediaplayer.status === MediaPlayer.Buffering
            || mediaplayer.status === MediaPlayer.Stalled
            || mediaplayer.status === MediaPlayer.Loading
            || mediaplayer.status === MediaPlayer.Loaded)
    readonly property bool _websiteLoading:
        http.status === Http.StatusRunning
        || networkErrorTimer.running

    readonly property bool loadingVideo: _mediaPlayerVideoLoading || _websiteLoading
    readonly property bool _waitingOnFirstVideoImage: !videoOutput.visible && mediaplayer.playbackState === MediaPlayer.PlayingState
    readonly property bool showBusyIndicator:
        loadingVideo || _forceBusyIndicator || _waitingOnFirstVideoImage
    property bool _restartHttp: false
    property bool _playBestFormatOnResume: false
    property bool _videoControlGesturesEnabled: videoOutput.visible
    property string _videoUrlFetchUrl

    Http {
        id: http

        onStatusChanged: {
            switch (status) {
            case Http.StatusCompleted:
                console.debug("completed error=" + error)
                if (Http.ErrorNone === error) {
                    if (url === videoUrl) {
                        _parseVideoData(data)
                        if (_videoUrlFetchUrl) {
                            get(_videoUrlFetchUrl)
                        } else {
                            //% "No video urls found"
                            var message = qsTrId("ph-video-player-page-no-urls-found")
                            window.notify(message)
                            openControlPanel()
                        }
                    } else if (url === _videoUrlFetchUrl) {
                        try {
                            _parseVideoUrlFetchUrlData(data)

                            if (_formats.length) {
                                if (_pauseCount) {
                                    _playBestFormatOnResume = true
                                } else {
                                    _playBestFormat()
                                }
                            } else {
                                //% "No video urls found"
                                var message = qsTrId("ph-video-player-page-no-urls-found")
                                window.notify(message)
                                openControlPanel()
                            }
                        } catch (error) {
                            console.debug(error)
                            console.debug(data)
                        }
                    } else {
                        console.debug(data)
                        switch (_action) {
                        case actionVoteUp:
                            break
                        case actionVoteDown:
                            break
                        case actionToggleFavorite:
                            try {
                                // {"action":"add","message":"","url":"\/video\/favourite?id=214353492&amp;toggle=1&amp;token=MTU1NDQ3ODMxOTXQEC3kpv-AUEGZKXXNOK0EAV0Tp8CK310tStFa2rtBnRPufgQsNXVBzVmQ2o7jX8B0WD9ZtUnUH5kNLS5aQmU.","success":"true"}


                                if (jsonObject.success === "true") {
                                    _isFavorite = jsonObject.action === "remove" // looks wrong, I know
                                } else {
                                    window.notify(jsonObject.message)
                                }
                            } catch (error) {
                                console.debug(error)
                                console.debug(data)
                            }
                            break
                        case actionFetchVideoUrls:

                        }
                    }
                } else {
                    window.downloadError(url, error, errorMessage)
                    openControlPanel()
                }
                break
            }
        }
    }

    Timer {
        id: stallTimer
        interval: 10000
        onTriggered: {
            console.debug("stall timer expired")
            _pauseDueToStall = true
            pause()
            openControlPanel()
        }
    }

    Timer {
        id: networkErrorTimer
        interval: 1666
        onTriggered: {
            console.debug("network error timer expired")
            mediaplayer.source = ""
            http.get(videoUrl)
        }
    }

    Timer {
        id: stateMachineTimer
        interval: 100
        repeat: true
        running: true
        onTriggered: {
            for (var i = 0; i < _stateMachines.length; ++i) {
                var stateMachine = _stateMachines[i]
                stateMachine.tick()
            }
        }
    }


    MediaPlayer {
        id: mediaplayer
        autoPlay: true

        onPositionChanged: {
            if (MediaPlayer.NoError === error &&
                MediaPlayer.Buffered === status) {
                _networkErrorRetryCount = 0
            }
        }

        onStatusChanged: {
            console.debug("media player status=" + status)
            switch (status) {
            case MediaPlayer.Buffering:
                console.debug("buffering")
                stallTimer.start()
                break
            case MediaPlayer.Stalled:
                console.debug("stalled")
                stallTimer.start()
                break
            case MediaPlayer.Buffered:
                console.debug("buffered")
                stallTimer.stop()
                if (_pauseDueToStall) {
                    _pauseDueToStall = false
                    resume()
                    closeControlPanel()
                }
                break
            case MediaPlayer.EndOfMedia:
                console.debug("end of media")
                openControlPanel()
                break
            case MediaPlayer.Loaded:
                console.debug("loaded")
                break
            case MediaPlayer.InvalidMedia:
                console.debug("invalid media")
                break
            case MediaPlayer.NoMedia:
                console.debug("no media")
                break
            case MediaPlayer.Loading:
                console.debug("loading")
                break
            case MediaPlayer.UnknownStatus:
                console.debug("unknown status")
                break
            default:
                console.debug("unhandled status")
                break
            }
        }

        onPlaybackStateChanged: {
            console.debug("media player playback state=" + playbackState)

            switch (playbackState) {
            case MediaPlayer.PlayingState:
                console.debug("playing")
                break
            case MediaPlayer.PausedState:
                console.debug("paused")
                break
            case MediaPlayer.StoppedState:
                console.debug("stopped")
                break
            default:
                console.debug("unhandled playback state")
                break
            }

            _displayBlanking.preventBlanking = playbackState === MediaPlayer.PlayingState
        }

        onErrorChanged: {
            console.debug("media player error=" + error)

            switch (error) {
            case MediaPlayer.NoError:
                console.debug("no error")
                break
            case MediaPlayer.ResourceError:
                console.debug("resource error")
                //% "Resource error"
                var message = qsTrId("ph-video-player-resource-error")
                _onMediaPlayerError(message)
                break
            case MediaPlayer.FormatError:
                console.debug("format error")
                openControlPanel()
                break
            case MediaPlayer.NetworkError:
                console.debug("network error")
                //% "Network error"
                var message = qsTrId("ph-video-player-network-error")
                _onMediaPlayerError(message)
                break
            case MediaPlayer.AccessDenied:
                console.debug("access denied")
                openControlPanel()
                break
            case MediaPlayer.ServiceMissing:
                console.debug("service missing")
                openControlPanel()
                break
            default:
                console.debug("unhandled error")
                break
            }
        }
    }

    Rectangle {
        id: videoOutputRectangle
        anchors.fill: parent
        color: "black"

        VideoOutput {
            id: videoOutput
            source: mediaplayer
            visible: false
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectFit
        }

        BusyIndicator {
            anchors.centerIn: parent
            running: showBusyIndicator
            size: BusyIndicatorSize.Medium
        }


        Rectangle {
            id: seekRectangle
            color: "white"
            width: Theme.horizontalPageMargin * 2 + seekLabel.width
            height: 2*Theme.fontSizeExtraLarge
            visible: false
            anchors.centerIn: parent
            layer.enabled: true
            radius: Theme.itemSizeSmall

            Label {
                id: seekLabel
                color: "black"
                text: ""
                font.bold: true
                font.pixelSize: Theme.fontSizeExtraLarge
                anchors.centerIn: parent
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            property real startx: -1
            property real starty: -1
//            readonly property real dragDistance: Theme.iconSizeLarge / 2
            readonly property real dragDistance: Theme.startDragDistance

            property bool held: false
            property int seekType: -1
            property real initialVolume: 0

            onPositionChanged: function (e) {

//                console.debug("x=" + e.x + " y="+e.y)
                e.accepted = true

                if (_videoControlGesturesEnabled) {
                    if (startx >= 0 && starty >= 0) {
                        var dx = e.x - startx
                        var dy = e.y - starty

                        if (-1 === seekType) {
                            if (Math.abs(dx) >= dragDistance ||
                                Math.abs(dy) >= dragDistance) {

                                if (Math.abs(dx) >= Math.abs(dy)) {
                                    seekType = 0
                                } else {
                                    seekType = 1
                                }
                            }
                        }

                        seekRectangle.visible = seekType !== -1
                        switch (seekType) {
                        case 0: { // position
                            var skipSeconds = computePositionSeek(dx)
                            var streamPosition = Math.max(0, Math.min(streamPositonS + skipSeconds, streamDurationS))
                            seekLabel.text = (dx >= 0 ? "+" : "-") + _toTime(Math.abs(skipSeconds)) + " (" + _toTime(streamPosition) + ")"
                        } break
                        case 1: { // volume
                            var volumeChange = -(dy / parent.height)
                            var volume = Math.max(0, Math.min(initialVolume + volumeChange, 1))
                            seekLabel.text = "Volume " + (volume * 100).toFixed(0) + "%"
                            mediaplayer.volume = volume
                        } break
                        }
                    }
                } else {
                    seekType = -1 // disable seek
                }
            }

            onPressed: function (e) {
//                console.debug("pressed")
                if (!controlPanel.open) {
                    startx = e.x;
                    starty = e.y;
                    initialVolume = mediaplayer.volume
                }
            }

            onReleased: function (e) {
//                console.debug("released")

                var dx = e.x - startx
                var dy = e.y - starty

                switch (seekType) {
                case 0: { // position
                        var skipSeconds = computePositionSeek(dx)
                        if (Math.abs(skipSeconds) >= 3) { // prevent small skips
                            var streamPosition = Math.floor(Math.max(0, Math.min(streamPositonS + skipSeconds, streamDurationS)))
                            if (streamPosition !== streamPositonS) {
                                console.debug("skip to=" + streamPosition)
                                _seek(streamPosition * 1000)
                            }
                        }
                } break
                case 1: { // volume
//                    var volumeChange = -dy / dragDistance
//                    var volume = Math.max(0, Math.min(mediaplayer.volume + volumeChange, 1))
//                    mediaplayer.volume = volume
                } break
                default: {
                    if (!held) {
                        if (_clickedToOpen) {
                            _clickedToOpen = false
                            closeControlPanel()
                        } else {
//                            mediaplayer.pause()
                            if (!_clickedToOpen) {
                                _clickedToOpen = true
                                openControlPanel()
                            }
                        }
                    }
                } break
                }

                seekType = -1
                held = false
                startx = -1
                starty = -1
                seekRectangle.visible = false
                initialVolume = 0
            }

            onPressAndHold: function (e) {
                console.debug("onPressAndHold")
                e.accepted = true
                held = true
            }

            function computePositionSeek(dx) {
                var sign = dx < 0 ? -1 : 1
                var absDx = sign * dx
                return sign * Math.pow(absDx / dragDistance, 1 + absDx / Screen.width)
            }

            DockedPanel {
                id: controlPanel
                width: parent.width
                height: 2*Theme.itemSizeLarge
                dock: Dock.Bottom

                onOpenChanged: {
                    console.debug("control panel open=" + open)
                }

                Column {
                    width: parent.width

                    Slider {
                        id: positionSlider
                        width: parent.width
                        maximumValue: Math.max(1, mediaplayer.duration)

                        Connections {
                            target: mediaplayer
                            onPositionChanged: {
                                if (!positionSlider.down && !seekTimer.running) {
                                    positionSliderConnections.target = null
                                    positionSlider.value = Math.max(0, mediaplayer.position)
                                    positionSliderConnections.target = positionSlider
                                }
                            }
                        }

                        Connections {
                            id: positionSliderConnections
                            target: positionSlider
                            onValueChanged: {
                                console.debug("onValueChanged " + positionSlider.value + " down=" + positionSlider.down)
                                seekTimer.restart()
                            }
                        }

                        Timer {
                            id: seekTimer
                            running: false
                            interval: 500
                            repeat: false
                            onTriggered: {
                                _seek(positionSlider.sliderValue)
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: first.height

                        Item {
                            id: leftMargin
                            width: Theme.horizontalPageMargin
                            height: parent.height
                            anchors.left: parent.left
                        }

                        Item {
                            id: rightMargin
                            width: Theme.horizontalPageMargin
                            height: parent.height
                            anchors.right: parent.right
                        }

                        Label {
                            id: first
                            anchors.left: leftMargin.right
                            text: _toTime(streamPositonS)
                            font.pixelSize: Theme.fontSizeExtraSmall
                        }

                        Label {
                            anchors.right: rightMargin.left
                            text: _toTime(streamDurationS)
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.highlightColor
                        }
                    }

                    Item {
                        width: parent.width
                        height: functionalButtonRow.height

                        Item {
                            id: leftMargin2
                            width: Theme.horizontalPageMargin
                            height: parent.height
                            anchors.left: parent.left
                        }

                        Item {
                            id: rightMargin2
                            width: Theme.horizontalPageMargin
                            height: parent.height
                            anchors.right: parent.right
                        }

                        Row {
                            id: functionalButtonRow
                            anchors.centerIn: parent
                            spacing: Theme.paddingLarge

                            IconButton {
                                icon.source: isPlaying
                                             ? "image://theme/icon-m-pause"
                                             : (mediaplayer.status === MediaPlayer.EndOfMedia
                                                ? "image://theme/icon-m-reload"
                                                : "image://theme/icon-m-play")
                                anchors.verticalCenter: parent.verticalCenter
                                onClicked: {
                                    console.debug("play/pause")
                                    switch (mediaplayer.playbackState) {
                                    case MediaPlayer.PlayingState:
                                        page.pause()
                                        break
                                    case MediaPlayer.PausedState:
                                    case MediaPlayer.StoppedState:
                                        switch (mediaplayer.status) {
                                        case MediaPlayer.Buffered:
                                            page.resume()
                                            break
                                        case MediaPlayer.EndOfMedia:
                                            closeControlPanel()
                                            _seek(0)
                                            mediaplayer.play()
                                            break
                                        }
                                        break
                                    }
                                }
                            }


                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: leftMargin2.right
                            spacing: Theme.paddingMedium


                            Label {
                                visible: videoOutput.sourceRect.width > 0 && videoOutput.sourceRect.height > 0
                                text: videoOutput.sourceRect.width + "x" + videoOutput.sourceRect.height
                                font.pixelSize: Theme.fontSizeExtraSmall
                                color: Theme.highlightColor
                            }

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.paddingSmall
                                visible: _upVotes >= 0 && _downVotes >= 0

                                BestEffortIcon {
                                    width: Theme.iconSizeExtraSmall
                                    height: Theme.iconSizeExtraSmall
                                    source: "file://" + App.appDir + "/media/thumbs-up-filled-white.png"

//                                    ColorOverlay {
//                                        anchors.fill: parent
//                                        source: parent
//                                        color: Theme.primaryColor
//                                    }
                                }

                                Label {
                                    text: _upVotes.toFixed(0)
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    color: Theme.highlightColor
                                }

                                BestEffortIcon {
                                    width: Theme.iconSizeExtraSmall
                                    height: Theme.iconSizeExtraSmall
                                    source: "file://" + App.appDir + "/media/thumbs-down-filled-white.png"

//                                    ColorOverlay {
//                                        anchors.fill: parent
//                                        source: parent
//                                        color: Theme.primaryColor
//                                    }
                                }

                                Label {
                                    text: _downVotes.toFixed(0)
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    color: Theme.highlightColor
                                }
                            }
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: rightMargin2.left
                            spacing: Theme.paddingLarge



                            IconButton {
                                visible: _categories.length > 0
                                icon.width: Theme.iconSizeSmallPlus
                                icon.height: Theme.iconSizeSmallPlus
                                icon.source: "image://theme/icon-m-about"
                                anchors.verticalCenter: parent.verticalCenter
                                onClicked: {
                                    pageStack.replace(
                                                Qt.resolvedUrl("VideosPage.qml"),
                                                {
                                                    //% "%1's Videos"
                                                    videosUrl: Constants.baseUrl + _modelUrl + "/videos",
                                                    title: qsTrId("ph-model-videos-page-title").arg(_modelName)
                                                })
                                }
                            }

                            IconButton {
                                visible: _modelName && _modelUrl
                                icon.width: Theme.iconSizeSmallPlus
                                icon.height: Theme.iconSizeSmallPlus
                                //icon.source: "image://theme/icon-m-person"
                                icon.source: "image://theme/icon-m-media-artists"
                                anchors.verticalCenter: parent.verticalCenter
                                onClicked: {
                                    pageStack.replace(
                                                Qt.resolvedUrl("VideosPage.qml"),
                                                {
                                                    //% "%1's Videos"
                                                    videosUrl: Constants.baseUrl + _modelUrl + "/videos",
                                                    title: qsTrId("ph-model-videos-page-title").arg(_modelName)
                                                })
                                }
                            }

                            IconButton {
                                visible: false && window.isUserLoggedIn && _ratingToken
                                icon.width: Theme.iconSizeSmallPlus
                                icon.height: Theme.iconSizeSmallPlus
                                icon.source: "file://" + App.appDir + "/media/thumbs-up-outlined.png"
                                anchors.verticalCenter: parent.verticalCenter
                                onClicked: {
                                    _action = actionVoteUp
                                    var postArgs = App.urlEncode({
                                                                     token: _ratingToken,
                                                                     id: videoId,
                                                                     value: 1,
                                                                 })
//                                    http.post(Constants.baseUrl + "/video/rate", postArgs)
                                    http.post(Constants.baseUrl + "/video/rate?" + postArgs)
                                }
                            }

                            IconButton {
                                visible: false && window.isUserLoggedIn && _ratingToken
                                icon.width: Theme.iconSizeSmallPlus
                                icon.height: Theme.iconSizeSmallPlus
                                icon.source: "file://" + App.appDir + "/media/thumbs-down-outlined.png"
                                anchors.verticalCenter: parent.verticalCenter
                                onClicked: {
                                    _action = actionVoteDown
                                    var postArgs = App.urlEncode({
                                                                     token: _ratingToken,
                                                                     id: videoId,
                                                                     value: 0,
                                                                 })
                                    http.post(Constants.baseUrl + "/video/rate?" + postArgs)
                                }
                            }

                            IconButton {
                                visible: window.isUserLoggedIn && _ratingToken
                                icon.width: Theme.iconSizeSmallPlus
                                icon.height: Theme.iconSizeSmallPlus
                                icon.source: _isFavorite
                                             ? "file://" + App.appDir + "/media/heart-filled-white.png"
                                             : "file://" + App.appDir + "/media/heart-outlined.png"
                                anchors.verticalCenter: parent.verticalCenter
                                onClicked: {
                                    _action = actionToggleFavorite
                                    var postArgs = App.urlEncode({
                                                                     token: _ratingToken,
                                                                     id: videoId,
                                                                     toggle: (_isFavorite ? 0 : 1),
                                                                 })
                                    http.post(Constants.baseUrl + "/video/favourite", postArgs)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        _displayBlanking = _createDisplayBlanking()
        window.videoPlayerPage = page
        http.get(videoUrl)

        _createVideoStm()
    }

    Component.onDestruction: {
        console.debug("destruction")
        _displayBlanking.preventBlanking = false
        mediaplayer.pause()
        window.videoPlayerPage = null
    }


    Timer {
        id: busyTimer
        interval: 1000
        onTriggered: {
            console.debug("_forceBusyIndicator = false")
            _forceBusyIndicator = false
        }
    }

    onStatusChanged: {
        console.debug("page status=" + status)
        switch (status) {
        case PageStatus.Deactivating:
            console.debug("page status=deactivating")
            break
        case PageStatus.Activating:
            console.debug("page status=activating")
            break
        }
    }

    function play(url) {
        console.debug("play url=" + url)
        mediaplayer.source = url
        mediaplayer.play()
        controlPanel.open = false
        _clickedToOpen = false
        _openCount = 0
        _pauseCount = 0;
        _paused = false
        _restartHttp = false
        _playBestFormatOnResume = false
    }

    function pause() {
        _pauseCount += 1
        console.debug("pause count="+ _pauseCount)

        stateMachineTimer.running = false

        if (isPlaying) {
            console.debug("video player page pause playback")
            _paused = true
            mediaplayer.pause()
        }
    }

    function resume() {
        _pauseCount -= 1
        console.debug("pause count="+ _pauseCount)
        if (_pauseCount === 0) {
            stateMachineTimer.running = true

            if (_restartHttp) {
                _restartHttp = false
                http.get(videoUrl)
            }

            if (_playBestFormatOnResume) {
                _playBestFormat()
            }

            if (_paused) {
                console.debug("video player page resume playback")
                _paused = false
                mediaplayer.play()

                // toggle item visibility to to unfreeze video
                // after coming out of device lock
                videoOutputRectangle.visible = false
                videoOutputRectangle.visible = true
            }
        }
    }

    function openControlPanel() {
        _openCount += 1
        console.debug("open count="+ _openCount)
        if (!controlPanel.open) {
            console.debug("opening control pannel")
            controlPanel.open = true
        }
    }

    function closeControlPanel() {
        _openCount -= 1
        console.debug("open count="+ _openCount)
        if (_openCount === 0 && controlPanel.open) {
            console.debug("closing control panel")
            controlPanel.open = false
        }
    }

    function _toTime(n) {
        return _secondsToTimeString(n)
    }

    function _seek(position) {
        _forceBusyIndicator = true
        console.debug("_forceBusyIndicator=true")
        busyTimer.restart()
        mediaplayer.seek(position)
    }

    function _parseVideoData(data) {
        var flashVarsVarName = "flashvars_" + videoId
        var emptyOrWhitespaceRegex = new RegExp("^\\s*$")
        var flashVarsRegex = new RegExp("<script\\s+type=[\"']text/javascript[\"']\\s*>\\s*(var\\s+" + flashVarsVarName + "\\s*=.+?)\\s*</script>")
        var jsVarDefinitionRegex = new RegExp("^\\s*var\\s+([a-zA-Z_][a-zA-Z_0-9]*)\\s*=\\s*(.+)\\s*$")
        //var jsLineCommentRegex = new RegExp("^(.*?)//.*$")
        var jsLineCommentRegex = new RegExp("^\\s*//.*$") // wrong but works for urls
        var jsRangeCommentRegex = new RegExp("/\\*.*?\\*/", "g")


        var ratingRegex = new RegExp("^\\s*var\\s+WIDGET_RATINGS_LIKE_FAV\\s*=\\s*(\\{(.+?)\\})\\s*;?\\s*$")
        var ratingTokenRegex = new RegExp("^\\s*WIDGET_RATINGS_LIKE_FAV.token\\s*=\\s*\"(.+?)\"")
        var modelRegex = new RegExp("<a\\s+.*?href=[\"']([^\"']+)[\"']\\s+class=[\"']bolded[\"'][^>]*>([^<]+)</a>")
        /*class="bolded"
                <div class="usernameWrap clearfix" data-type="user" data-userid="313532711" data-liu-user="0" data-json-url="/user/box?id=313532711&amp;token=MTU1OTQ5NzExMi0HQ8Bu2IQ-Df8mIbhL2eVzXWjtLcwn66zG4l5w1MOT7zo7-UuNfgcmdIgPrInEUHMYGsk-SQZ-WxR0KWR_KI4." data-disable-popover="0">
                    <a rel="" href="/model/yummy-couple"  class="bolded">Yummy Couple</a>
                <div class="avatarPosition"></div>

                <a rel="" href="/pornstar/leolulu"  class="bolded">Leolulu</a>
        */



        var categoriesRegex = new RegExp("<div\\s+id=\"category-box\"\\s+class=\"suggest-mini-box\">(.+?)</ul>")
        var categoryRegex = new RegExp("<li>\\s*<button\\s+.*?data-categoryid=\"(\\d+)\".*?>\\s*</button>\\s*<button\\s+.*?>\\s*</button>([^<]+)</li>", "g")

//                <div class="pornstarsWrapper">
//                    Pornstars:&nbsp;
//                                                        <a class="pstar-list-btn js-mxp" data-mxptype="Pornstar" data-mxptext="Ada Sanchez" data-id="64801" data-login="1" href="/pornstar/ada-sanchez">Ada Sanchez				<span class="psbox-link-container display-none"></span>
//                            </a>
//                                        , 					<a class="pstar-list-btn js-mxp" data-mxptype="Pornstar" data-mxptext="Ralph Long" data-id="3401" data-login="1" href="/pornstar/ralph-long">Ralph Long				<span class="psbox-link-container display-none"></span>
//                            </a>
//                                                                <div class="tooltipTrig suggestBtn" data-title="Add a pornstar">
//                            <a class="add-btn-small add-pornstar-btn-2" >+ <span>Suggest</span></a>
//                        </div>

        var pornstarsRegex = new RegExp("<div\\s+class=\"pornstarsWrapper\">(.*?)</div>")
        var pornstarRegex = new RegExp("<a\\s+.*?data-mxptext=\"(.+?)\".+?href=\"(.+?)\".*?>.+?</a>", "g")


//                <div class="tagsWrapper">
//                               Tags:&nbsp;
//                               <a href="/video?c=7">big dick</a>, <a href="/video?c=26">latina</a>, <a href="/video/search?search=teengonzo">teengonzo</a>, <a href="/categories/teen">teen</a>, <a href="/video/search?search=hispanic">hispanic</a>, <a href="/video/search?search=thick">thick</a>, <a href="/video/search?search=chubby">chubby</a>, <a href="/video?c=8">big tits</a>, <a href="/video/search?search=cumshot">cumshot</a>, <a href="/video/search?search=facial">facial</a>, <a href="/categories/teen">teenager</a>, <a href="/video/search?search=young">young</a>, <a href="/video/search?search=latin">latin</a>, <a href="/video/search?search=big+boobs">big boobs</a>, <a href="/video/search?search=busty">busty</a>, <a href="/video/search?search=shaved">shaved</a>                <div class="tooltipTrig suggestBtn" data-title="Suggest Tags" >
//                                   <a id="tagLink" class="add-btn-small">+ <span>Suggest</span></a>
//                               </div>
//                           </div>

        var tagsRegex = new RegExp("<div\\s+class=\"tagsWrapper\">(.*?)</div>")
        var tagRegex = new RegExp("<a\\s+href=\"(.+?)\">([^<]+)</a>", "g")
        /*
          <li>                                         <button type="button" class="upVote" data-categoryid="7" data-suggestcategory-url="/video/rate_category?current=7&id=206039581&value=1&token=MTU1OTU5MDIzMIy2CCnncc2t9i9ewj0WDwtEEPYZdXWI7XWtzkSc7dPVbJ1_3cxidde9lAPjk7WVwvrP4KHt2iIRwcjlVC8Hy-o."></button>                                         <button type="button" class="downVote" data-categoryid="7" data-suggestcategory-url="/video/rate_category?current=7&id=206039581&value=0&token=MTU1OTU5MDIzMIy2CCnncc2t9i9ewj0WDwtEEPYZdXWI7XWtzkSc7dPVbJ1_3cxidde9lAPjk7WVwvrP4KHt2iIRwcjlVC8Hy-o."></button>                                         Big Dick                                    </li>
          */
        var hasFoundSessionInfo = false
        // WIDGET_RATINGS_LIKE_FAV.token = "MTU1NDM4MTkwNB_j3wXL9yAhG4cE4CAfoYXshRU63e1Q14DWT8QqCmcgcRjqdwcmutv0HXoEuUowLgHVkxptmjxQ3Ep60i8qbYc." </script>
        _ratingToken = ""
        _isFavorite = false
        _modelUrl = ""
        _modelName = ""
        _upVotes = -1
        _downVotes = -1
        _categories = []
        _pornstars = []
        _tags = []
        _formats = []
        _videoUrlFetchUrl = ""


        var oneline = data.replace(new RegExp("\r|\n", "g"), "\v") // Qt doesn't have 's' flag to match newlines with .

        var categoriesMatch = categoriesRegex.exec(oneline)
        if (categoriesMatch) {
            var categoriesData = categoriesMatch[1]
//            console.debug(categoriesData)
            for (var categoryMatch; (categoryMatch = categoryRegex.exec(categoriesData)) !== null; ) {
                var categoryId = parseInt(categoryMatch[1])
                var category = {
                    category_id: categoryId,
                    category_title: categoryMatch[2].trim(),
                    category_url: Constants.baseUrl + "/video?c=" + categoryId,
                }

                _categories.push(category)
                console.debug("adding category id=" + category.category_id)
            }
        }

        var pornstarsMatch = pornstarsRegex.exec(oneline)
        if (pornstarsMatch) {
            var pornstarsData = pornstarsMatch[1]
            for (var pornstarMatch; (pornstarMatch = pornstarRegex.exec(pornstarsData)) !== null; ) {
                var pornstar = {
                    pornstar_name: pornstarMatch[1],
                    pornstar_url: Constants.baseUrl + pornstarMatch[2],
                }

                _pornstars.push(pornstar)
                console.debug("adding pornstar name=" + pornstar.pornstar_name)
            }
        }

        var tagsMatch = tagsRegex.exec(oneline)
        if (tagsMatch) {
            var tagsData = tagsMatch[1]
            for (var tagMatch; (tagMatch = tagRegex.exec(tagsData)) !== null; ) {
                var tag = {
                    tag_name: tagMatch[2].trim(),
                    tag_url: Constants.baseUrl + tagMatch[1],
                }

                _tags.push(tag)
                console.debug("adding tag name=" + tag.tag_name)
            }
        }

        var flashVarsMatch = flashVarsRegex.exec(oneline)
        if (flashVarsMatch) {
            var singleLineCode = flashVarsMatch[1]

            var singleLineCodeRangeCommentsRemoved = singleLineCode.replace(jsRangeCommentRegex, "")
            if (window.debugVideoPlayer) {
                console.debug("single: " + singleLineCode)
                console.debug("single w/o range comments: " + singleLineCodeRangeCommentsRemoved)
            }
//            var multiLineCode = singleLineCode.replace(new RegExp("\v", "g"), "\n") // Qt doesn't have 's' flag to match newlines with .
//            console.debug("multi: " + multiLineCode)
            singleLineCode = singleLineCodeRangeCommentsRemoved

            var lines = singleLineCode.split("\v")
            singleLineCode = ""
            for (var j = 0; j < lines.length; ++j) {
                var line = lines[j]
                var lineCommentMatch = jsLineCommentRegex.exec(line)
                if (lineCommentMatch) {
                    if (window.debugVideoPlayer) {
                        console.debug("line comment: " + lines[j])
                    }
                    continue
                }

                if (emptyOrWhitespaceRegex.exec(line)) {
                    if (window.debugVideoPlayer) {
                        console.debug("empty: " + lines[j])
                    }
                    continue
                }

                if (window.debugVideoPlayer) {
                    console.debug("code: " + line)
                }

                singleLineCode += line + " "
            }

            var defs = {}
            var stmts = singleLineCode.split(";")
            for (var j = 0; j < stmts.length; ++j) {
                var stmt = stmts[j]
                if (window.debugVideoPlayer) {
                    console.debug("stmt: " + stmt)
                }

                var jsVarDefinitionMatch = jsVarDefinitionRegex.exec(stmt)
                if (jsVarDefinitionMatch) {
                    defs[jsVarDefinitionMatch[1]] = jsVarDefinitionMatch[2]
                }
            }

            if (window.debugVideoPlayer) {
                console.debug("defs: " + JSON.stringify(defs))
            }

//            var flashvars_json = MiniJS.evaluate(defs, flashVarsVarName)
//            if (window.debugVideoPlayer) {
//                console.debug("flashvars_json: " + flashvars_json)
//            }

//            var flashvars = JSON.parse(flashvars_json)
//            //            if (window.debugVideoPlayer) {
//                            console.debug("flashvars: " + flashvars)
//            //            }

            var key = "media_0"
            if (key in defs) {
                _videoUrlFetchUrl = MiniJS.evaluate(defs, key)
                console.debug("key=" + key + " url=" + _videoUrlFetchUrl)
            }
        }

//        console.debug(data)

        var want = 4
        var lines = data.split('\n');
        for (var i = 0; i < lines.length && want > 0; ++i) {
            var ratingsMatch = ratingRegex.exec(lines[i])
            if (ratingsMatch) {
                --want
                try {
                    console.debug("rating JSON: " + ratingsMatch[1])
                    var jsonObject = JSON.parse(ratingsMatch[1])

                    // jsonObject.canVote seems to always be set to 1
//                        if (jsonObject.canVote) {
//                            _canVote = true
//                        } else {
//                            _canVote = false
//                        }

                    //console.debug("canVote=" + _canVote)

                    // jsonObject.loggedIn appears to have login status

                    if (jsonObject.isFavourite === 1) {
                        _isFavorite = true
                    } else {
                        _isFavorite = false
                    }

                    console.debug("isFavorite=" + _isFavorite)

                    _upVotes = jsonObject.currentUp
                    _downVotes = jsonObject.currentDown
                    console.debug("upVotes=" + _upVotes + " downVotes=" + _downVotes)

                } catch (error) {
                    console.debug(error)
                }
            } else {
                var tokenMatch = ratingTokenRegex.exec(lines[i])
                if (tokenMatch) {
                    --want
                    _ratingToken = tokenMatch[1]
                    console.debug("rating token=" + _ratingToken)
                } else {
                    if (!hasFoundSessionInfo && window.updateSessionLine(lines[i])) {
                        --want
                        hasFoundSessionInfo = true
                    }

                    var modelMatch = modelRegex.exec(lines[i])
                    if (modelMatch) {
                        --want
                        _modelUrl = modelMatch[1]
                        _modelName = modelMatch[2]
                        console.debug("model name=" + _modelName + " model url=" + _modelUrl)
                    }
                }
            }
        }

        if (window.debugVideoPlayer || (window.isUserLoggedIn && !_ratingToken)){
            console.debug(data)
        }
    }

    function _parseVideoUrlFetchUrlData(data) {
        if (window.debugVideoPlayer) {
            console.debug("url data=" + data)
        }

        var video_urls = JSON.parse(data)
        var formats = []

        for (var j = 0; j < video_urls.length; ++j) {
            var item = video_urls[j]

            if ("videoUrl" in item && "quality" in item) {
                var quality = item["quality"]

                if (Array.isArray(quality)) {
                    continue
                }

                var format = {
                    format_quality: _parseVideoQuality(quality),
                    format_url: item["videoUrl"]
                }

                formats.push(format)
                console.debug("added quality=" + format.format_quality + " url=" + format.format_url)
            }
        }

        _formats = formats

        // remove formats without url
        for (var j = 0; j < _formats.length; ) {
            if (!_formats[j].format_url) {
                console.debug("removing format w/o url at index=" + j + " quality=" + _formats[j].format_quality)
                _formats.splice(j, 1)
            } else {
                ++j
            }
        }
    }

    function _secondsToTimeString(n) {
        n = Math.round(n)
        var h = Math.floor(n / 3600)
        n = n - 3600 * h
        var m = Math.floor(n / 60)
        n = n - 60 * m
        var s = Math.floor(n)

        var result = ""
        if (h > 0) {
            result = (h < 10 ? ("0" + h.toString()) : h.toString()) + ":"
        }

        result = result + (m < 10 ? ("0" + m.toString()) : m.toString()) + ":"
        result = result + (s < 10 ? ("0" + s.toString()) : s.toString())
        return result
    }

    function _getVideoFormatFromBearerMode() {
        var formatId
        switch (settingBearerMode.value) {
        case Constants.bearerModeBroadband:
            console.debug("force broadband format selection")
            formatId = settingBroadbandDefaultFormat.value
            break
        case Constants.bearerModeMobile:
            console.debug("force mobile format selection")
            formatId = settingMobileDefaultFormat.value
            break
        default:
            if (App.isOnBroadband) {
                console.debug("use broadband format selection")
                formatId = settingBroadbandDefaultFormat.value
            } else if (App.isOnMobile) {
                console.debug("use mobile format selection")
                formatId = settingMobileDefaultFormat.value
            } else {
                console.debug("unknown bearer using mobile default format")
                formatId = settingMobileDefaultFormat.value
            }
            break
        }

        console.debug("format=" + formatId)

        return formatId
    }

    function _selectFormatIdFromHeight(height) {
        if (height <= 240) {
            return Constants.format240
        }

        if (height <= 480) {
            return Constants.format480
        }

        if (height <= 720) {
            return Constants.format720
        }

        if (height <= 1080) {
            return Constants.format1080
        }

        if (height <= 1440) {
            return Constants.format1440
        }

        if (height <= 2160) {
            return Constants.format2160
        }

        return Constants.formatUnknown
    }

    function _getAreaFromFormatQuality(q) {
        var targetArea = 1080*1920
        switch (q) {
        case 2160:
            targetArea = 2160*3840
            break
        case 1440:
            targetArea = 1440*2560
            break
        case 1080:
            targetArea = 1080*1920
            break
        case 720:
            targetArea = 720*1280
            break
        case 480:
            targetArea = 480*640
            break
        case 240:
            targetArea = 240*320
            break
        }

        return targetArea
    }

    function _findBestFormat(formatId) {
        var formatIndex = -1
        if (Constants.formatWorst === formatId) {
            var best = _formats[0]
            formatIndex = 0
            for (var i = 1; i < _formats.length; ++i) {
                var f = _formats[i]
                if (f.format_quality < best.format_quality) {
                    best = f;
                    formatIndex = i;
                }
            }
        } else if (Constants.formatBest === formatId) {
            var best = _formats[0]
            formatIndex = 0
            for (var i = 1; i < _formats.length; ++i) {
                var f = _formats[i]
                if (f.format_quality > best.format_quality) {
                    best = f;
                    formatIndex = i;
                }
            }
        } else {
            // try to find exact match
            for (var i = 0; i < _formats.length; ++i) {
                var f = _formats[i]
                if (f.format_quality === formatId) {
                    formatIndex = i
                    break
                }
            }

            if (formatIndex === -1) {
                var targetArea = _getAreaFromFormatQuality(formatId)

                formatIndex = 0
                var f = _formats[0]
                var bestdelta = Math.abs(_getAreaFromFormatQuality(f.format_quality) - targetArea)
                for (var i = 1; i < _formats.length; ++i) {
                    f = _formats[i]
                    var delta = Math.abs(_getAreaFromFormatQuality(f.format_quality) - targetArea)
                    if (delta < bestdelta) {
                        bestdelta = delta;
                        formatIndex = i;
                    }
                }
            }
        }

        return formatIndex
    }

    function _createDisplayBlanking() {
        try {
            console.info("Attempting to use Nemo.KeepAlive 1.2 DisplayBlanking")
            var x = Qt.createQmlObject(
                        "import QtQuick 2.0\n" +
                        "import Nemo.KeepAlive 1.2\n" +
                        "Item {\n" +
                        "   property alias preventBlanking: displayBlanking.preventBlanking\n" +
                        "   DisplayBlanking {id: displayBlanking}\n" +
                        "}\n",
                        root, "script");
            if (x) {
                console.info("Using Nemo.KeepAlive 1.2 DisplayBlanking")
                return x
            }
        } catch (e) {
            console.debug("exception: " + e.message)
        }

        try {
            // DisplayBlanking is a static here!
            console.info("Attempting to use Nemo.KeepAlive 1.1 DisplayBlanking")
            var x = Qt.createQmlObject(
                        "import QtQuick 2.0\n" +
                        "import Nemo.KeepAlive 1.1\n" +
                        "Item {\n" +
                        "   property bool preventBlanking: false\n" +
                        "   onPreventBlankingChanged: DisplayBlanking.preventBlanking = preventBlanking\n" +
                        "}\n",
                        root, "script");
            if (x) {
                console.info("Using Nemo.KeepAlive 1.1 DisplayBlanking")
                return x
            }
        } catch (e) {
            console.debug("exception: " + e.message)
        }

        console.warn("Display blanking prevention not available")
        return Qt.createQmlObject("import QtQuick 2.0; Item { property bool preventBlanking: false }", root, "script");
    }

    function _playBestFormat() {
// see comment at top of page
//        // update allowed orientations based on video format
//        var f = _formats[0]
//        if (f.height > f.width) {
//            page.allowedOrientations = Orientation.Portrait | Orientation.PortraitInverted
//        } else {
//            page.allowedOrientations = Orientation.Landscape | Orientation.LandscapeInverted
//        }

        // select format and play
        var formatId = _getVideoFormatFromBearerMode()
        var selectedFormatIndex = _findBestFormat(formatId)
        var format = _formats[selectedFormatIndex]
        play(format.format_url)
    }

    function _createVideoStm() {
        var stm = Stm.create("video")
        stm.setLogger(console.debug)

        var initial = stm.addState("initial")
        var picAvailable = stm.addState("picAvailable")
        var picVisible = stm.addState("picVisible")
        var startTime = 0
        var picAvailableCondition = function() {
            return MediaPlayer.NoError === mediaplayer.error &&
                    (MediaPlayer.Buffered === mediaplayer.status || MediaPlayer.Stalled === mediaplayer.status)
            }

        stm.addTransition(initial, picAvailable, picAvailableCondition,
            function() {
                startTime = new Date().getTime()
            })

        stm.addTransition(picAvailable, initial, function() {
                return !picAvailableCondition()
            })

        stm.addTransition(picAvailable, picVisible, function() {
                return picAvailableCondition() && new Date().getTime() - startTime >= 1000
            },
            function () {
                videoOutput.visible = true
            })

        stm.initialState = initial

        stm.start()

        _stateMachines.push(stm)
    }

    function _onMediaPlayerError(str) {
        console.debug("retry count=" + _networkErrorRetryCount)
        if (_networkErrorRetryCount < settingPlaybackVideoReloadAttempts.value) {
            if (_pauseCount) {
                _restartHttp = true
            } else {
                ++_networkErrorRetryCount
                mediaplayer.stop()
                networkErrorTimer.restart()
            }
        } else {
            window.notify(str)
            openControlPanel()
        }
    }

    function _parseVideoQuality(obj) {
        switch (typeof(obj)) {
        case "number":
            return Math.floor(obj)
        case "string":
            return parseInt(obj)
        default:
            return Constants.formatUnknown
        }
    }
}

