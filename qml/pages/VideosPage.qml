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
import grumpycat 1.0
import ".."
import "."
import "../Scraper.js" as Scraper

GridViewPage {
    id: root

    itemsPerRow: settingDisplayVideosPerRow.value
    onOrientationChanged: view.updateInfiniteScroll()

    property string videosUrl
    property string title
    property bool _reload: false
    property int _page: 0
    property bool _triedFallback: false
    property var _seen: ({})
    property bool cache: false
    property bool isSearch: false
    readonly property real overlayOpacity: 0.68
    readonly property bool _canTriggerLoadMore: _page >= 1 && http.status !== Http.StatusRunning

    ListModel {
        id: model
    }

    Http {
        id: http

        onStatusChanged: {
            switch (status) {
            case Http.StatusCompleted:
                console.debug("completed error=" + error + " http status=" + httpStatusCode)
                if (Http.ErrorNone === error) {
                    _parseVideos(data, url, root.cache)
                } else {
                    switch (httpStatusCode) {
                    case 404:
                        // some performers' video lists are only on their main page
                        if (_page === 0 && !_triedFallback && /\/videos$/.test(videosUrl)) {
                            _triedFallback = true
                            videosUrl = videosUrl.replace(/\/videos$/, "")
                            load()
                        } else if (!isSearch) {
                            window.downloadError(url, error, errorMessage)
                        }
                        break
                    default:
                        window.downloadError(url, error, errorMessage)
                        break
                    }
                }
                break
            }
        }
    }

    SilicaFlickable {

        anchors.fill: parent

        // Why is this necessary?
        contentWidth: parent.width


        VerticalScrollDecorator {}
        TopMenu {
            reloadCallback: function () {
                _reload = true
                model.clear()
                load()
            }
        }

        PushUpMenu {
            enabled: _canTriggerLoadMore
            MenuItem {
                //% "Load more"
                text: qsTrId("ph-push-up-menu-load-more")
                onClicked: _loadNextPage()
            }
        }

        SilicaGridView {
            id: view
            anchors.fill: parent
            model: model

            readonly property real visibleAreaHeight: height > 0 ? height : 1
            readonly property int maxVisibleRows: visibleAreaHeight / cellHeight + 1
            readonly property int maxVisibleItems: maxVisibleRows * _itemsPerRow
            property real _previousContentY: 0

            onContentYChanged: {
                if (_previousContentY < contentY) {
                    // scrolling down
                    updateInfiniteScroll()
                }

                _previousContentY = contentY
            }


            cellWidth: _targetCellWidth
            cellHeight: cellWidth * Screen.width / Screen.height

            header: PageHeader {
                id: header
                title: root.title
            }


            delegate: Component {
                ListItem {
                    id: videoItem

                    width: view.cellWidth
                    height: view.cellHeight


                    property var _playlist

                    menu: ContextMenu {
                        MenuItem {
                            //% "Copy URL to clipboard"
                            text: qsTrId("ph-videos-page-context-menu-copy-url-to-clipboard")
                            onClicked: Clipboard.text = video_url
                        }
                    }

                    FramedImage {
                        id: thumbnail
                        source: video_thumbnail
                        width: parent.width
                        height: sourceSize.height * width / sourceSize.width
                        title: video_title
                        bottomFrameHeight: bottomFrameContent.height + Theme.paddingSmall

                        bottomFrameContent: Row {
                            id: statsRow
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.paddingMedium

                            Label {
                                text: video_views
                                font.pixelSize: Theme.fontSizeExtraSmall
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                                color: thumbnail.textColor
                            }

                            Image {
                                visible: video_rating >= 0
                                width: Theme.iconSizeExtraSmall
                                height: Theme.iconSizeExtraSmall
                                source: "file://" + App.appDir + "/media/" + (video_rating >= 50 ? "thumbs-up-filled-green.png" : "thumbs-down-filled-red.png")
                            }

                            Label {
                                text: (video_rating >= 0 ? video_rating + "% " : "") + video_length
                                font.pixelSize: Theme.fontSizeExtraSmall
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                                color: thumbnail.textColor
                            }

                            Image {
                                width: Theme.iconSizeSmall
                                height: Theme.iconSizeSmall
                                visible: !!videoItem._playlist
                                source: "image://theme/icon-s-device-download"
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Item {
                                width: Theme.paddingSmall * 0.68
                                height: parent.height
                            }
                        }
                    }

                    onClicked: {
                        view.currentIndex = index
                        pageStack.push(Qt.resolvedUrl("VideoPlayerPage.qml"), {
                                                        videoId: video_id,
                                                        videoUrl: video_url,
                                                        videoTitle: video_title,
                                                        })
                    }
                }
            }

            ViewPlaceholder {
                enabled: view.count === 0
                text: {
                    if (http.status === Http.StatusRunning) {
                        //% "Videos are being loaded"
                        return qsTrId("ph-videos-page-view-placeholder-text-loading")
                    }

                    if (isSearch) {
                        //% "Search yielded no results"
                        return qsTrId("ph-view-placeholder-text-no-results")
                    }

                    return ":/"
                }
            }

            Component.onCompleted: {
                currentIndex = -1
                _previousContentY = contentY
            }

            function updateInfiniteScroll() {
                if (_canTriggerLoadMore) {
                    var index = indexAt(0, contentY)
                    if (index >= 0) {
                        if (index + maxVisibleItems >= count) {
                            console.debug("infinite scroll load next page")
                            _loadNextPage()
                        }
                    }
                }
            }
        }
    }

    BusyIndicator {
        size: BusyIndicatorSize.Large
        anchors.centerIn: parent
        visible: running
        running: view.count > 0 &&
                 http.status === Http.StatusRunning &&
                 http.url.indexOf(videosUrl) >= 0
    }

    Component.onCompleted: load()

    on_PageChanged: {
        console.debug("_page="+_page)
    }

    function load() {
        _page = 0
        _seen = {}
        var url = videosUrl
        if (_reload) {
            http.get(url)
        } else {
            var data = DownloadCache.load(url)
            if (data) {
                _parseVideos(data, url, false)
            } else {
                http.get(url)
            }
        }
    }

    function _parseVideos(data, url, storeInCache) {
        window.updateSessionHtml(data)

        var list = Scraper.parseVideoList(data)
        var added = 0
        for (var i = 0; i < list.videos.length; ++i) {
            var video = list.videos[i]
            if (!_seen[video.video_viewkey]) {
                _seen[video.video_viewkey] = true
                model.append(video)
                ++added
            }
        }
        console.debug("found " + list.videos.length + " videos (" + added + " new) in " + (list.container || "the whole page") + ", next page: " + list.hasNextPage)

        if (list.videos.length > 0) {
            if (storeInCache) {
                DownloadCache.store(url, data, 300)
            }

            ++_page

            if (!list.hasNextPage || !added) {
                _reload = false
                _page = -1
            }
        } else {
            _page = -1
            var message = window.problemMessage(data)
            if (message) {
                window.notify(message)
            } else if (!isSearch && model.count === 0) {
                //% "No video URLs found"
                window.notify(qsTrId("ph-videos-page-no-urls-found"))
            }
        }
    }

    function _makeUrl(baseUrl, newPart) {
        if (baseUrl.indexOf("?") >= 0) {
            return baseUrl + "&" + newPart
        }
        return baseUrl + "?" + newPart
    }

    function _loadNextPage() {
        http.get(_makeUrl(videosUrl, "page=" + (_page + 1)))
    }


}
