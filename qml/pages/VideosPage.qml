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

GridViewPage {
    id: root

    itemsPerRow: settingDisplayVideosPerRow.value
    onOrientationChanged: view.updateInfiniteScroll()

    property string videosUrl
    property string title
    property bool _reload: false
    property int _page: 0
    readonly property int videosToSkip: 4
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
                        if (!isSearch) {
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
            cellHeight: cellWidth * 9 / 16

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
                                width: Theme.iconSizeExtraSmall
                                height: Theme.iconSizeExtraSmall
                                source: "file://" + App.appDir + "/media/" + (video_rating >= 50 ? "thumbs-up-filled-green.png" : "thumbs-down-filled-red.png")
                            }

                            Label {
                                text: video_rating + "% " + video_length
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

        /*
<div class="img fade fadeUp videoPreviewBg">
                                    <a href="/view_video.php?viewkey=ph5aa1c96ba3ab9" title="mixed wrestling" class="img " data-related-url="/video/ajax_related_video?vkey=ph5aa1c96ba3ab9"  >

                                                                                <img
                    src="https://ci.phncdn.com/videos/201803/08/157408752/original/(m=ecuKGgaaaa)(mh=XNx4Vv6EvPO5pGY9)14.jpg"
                    data-thumb_url = "https://ci.phncdn.com/videos/201803/08/157408752/original/(m=ecuKGgaaaa)(mh=XNx4Vv6EvPO5pGY9)14.jpg"
                    alt="mixed wrestling"
                                            data-src = "https://ci.phncdn.com/videos/201803/08/157408752/original/(m=ecuKGgaaaa)(mh=XNx4Vv6EvPO5pGY9)14.jpg"
                                                                data-mediumthumb="https://ci.phncdn.com/videos/201803/08/157408752/original/(m=ecuKGgaaaa)(mh=XNx4Vv6EvPO5pGY9)14.jpg"
                                                                                    data-mediabook="https://cv.phncdn.com/videos/201803/08/157408752/180P_225K_157408752.webm?jqeR55BANwUgLH0FeD700AcFsF6--cccagjb2A1zYpSKvpK49UcL0dNELSo4slZvTdOJfRCdbM_sqEgmgTOIVSQxD0dPr6QDLIDl626dOZ0lU14Oquziknw39eQyt0MerIUC8XeURMtWR97GxeWSgbAhMlQcFRzxLN3lGqRHtjzcq-ER43zlRRVIGtamqEz-52kBpehX_u4"
                                        class="js-pop js-videoThumb js-videoThumbFlip thumb js-videoPreview lazy"
                    width="150"

                     class="rotating" data-video-id="157408752" data-thumbs="16" data-path="https://ci.phncdn.com/videos/201803/08/157408752/original/(m=eWdTGgaaaa)(mh=3j-71AlBzgHCfklz){index}.jpg"                    title="mixed wrestling" />

                                            </a>
                                                                                                <div class="marker-overlays js-noFade">
                        <var class="duration">21:24</var>
                                                    <span class="hd-thumbnail">HD</span>
                                                                                            </div>
            </div>
            */

        // next page link <li class="page_next"><a href="/video?c=111&amp;page=2" class="orangeButton">Next <img class="pagination_arrow_right" src="https://di.phncdn.com/www-static/images/rightArrow.png"></a></li>




        data = data.replace(new RegExp("\r|\n", "g"), " ") // Qt doesn't have 's' flag to match newlines with .

        window.updateSessionHtml(data)

        var videos = []
        var videosRegex = new RegExp("<li\\s+.*?_vkey=\"(.+?)\"\\s+.*?data-id=\"(.+?)\".*?>(.*?)</li>", "g")
        var videoDataRegex = new RegExp("<a\\s+.*?title\\s*=\\s*\"(.+?)\".*?>.*?<img\\s+.*?data-thumb_url\\s*=\\s*\"(.+?)\".*?/>.*?<var\\s+class\\s*=\\s*\"duration\".*?>(.+?)</var>.*?<span class=\"views\">\\s*<var>(.+?)</var>.*?</span>.*?<div class=\"value\">(.+?)</div>.*?<var class=\"added\">(.+?)</var>")
        var nextRegex = new RegExp("<li\\s+class=\"page_next\">\\s*<a href=\"(.+?)\".*?>.*?</li>")
        for (var videoMatch; (videoMatch = videosRegex.exec(data)) !== null; ) {
            var videoViewKey = videoMatch[1]
            var videoId = videoMatch[2]
            var videoDataHtml = videoMatch[3]

            var match = videoDataRegex.exec(videoDataHtml)
            if (match) {
//                console.debug(match)
                var video = {
                    video_url: Constants.baseUrl + "/view_video.php?viewkey=" + videoViewKey,
                    video_viewkey: videoViewKey,
                    video_id: videoId,
                    video_title: App.replaceHtmlEntities(match[1]),
                    video_thumbnail: App.replaceHtmlEntities(match[2]),
                    video_length: match[3],
                    video_views: match[4],
                    video_rating: parseInt(match[5]),
                    video_added: match[6],
                }

                videos.push(video)
                console.debug("adding id=" + video.video_id)
            }
        }

        var nextUrl = ""
        var nextMatch = nextRegex.exec(data)
        if (nextMatch) {
            nextUrl = Constants.baseUrl + nextMatch[1]
        }


        if (videos.length > videosToSkip) {

            if (storeInCache) {
                DownloadCache.store(url, data, 300)
            }

            ++_page

            if (!nextUrl) {
                _reload = false
                _page = -1
            }

            console.debug("adding " + (videos.length-videosToSkip) + " videos")

            for (var i = videosToSkip; i < videos.length; ++i) {
                var item = videos[i]
                model.append(item)
            }
        } else {
            console.debug(data)
            //% "No video URLs found"
            var message = qsTrId("ph-videos-page-no-urls-found")
            window.notify(message)
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
