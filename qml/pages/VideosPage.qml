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
 <li class="pcVideoListItem js-pop videoblock videoBox"
                    id="v363214972"
        data-video-id="363214972"
    data-video-vkey="ph5f9280abe0e56"
    data-id="363214972"
    data-segment="straight"
    data-entrycode="VidPg-premVid"
>
    <div class="wrap">
                <div class="phimage"

        >

                                        <div class="preloadLine"></div>
                                                            <a href="/view_video.php?viewkey=ph5f9280abe0e56" title="Hot babe tries fuck machine at college party"                        class="fade fadeUp videoPreviewBg linkVideoThumb js-linkVideoThumb img "
                        data-related-url="/video/ajax_related_video?vkey=ph5f9280abe0e56"
                                                >

                                                                                <img
                    src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7"
                    data-thumb_url = "https://ci.phncdn.com/videos/202010/23/363214972/original/(m=eafTGgaaaa)(mh=r75FaeXOiGECS4fS)7.jpg"
                    alt="Hot babe tries fuck machine at college party"
                                            data-src = "https://ci.phncdn.com/videos/202010/23/363214972/original/(m=eafTGgaaaa)(mh=r75FaeXOiGECS4fS)7.jpg"
                                                        data-mediumthumb="https://ci.phncdn.com/videos/202010/23/363214972/original/(m=eafTGgaaaa)(mh=r75FaeXOiGECS4fS)7.jpg"
                                                                    data-mediabook="https://cw.phncdn.com/videos/202010/23/363214972/180P_225K_363214972.webm?JekHkGwbwo9OsSkj789u3sHyoqvwyOPB6B_N6vVDX7VFsJ-BAiIS9HFJUVIqq0Nk5X5bLBQ2U4IFthfd1RJVYajpCI9CPzwHapToAXRkSoSO4DA007AYPjQWSvdM7vtwPWYhXlFJeUGGogRHD2_b3Hnv-Q1p_UR-tlwD1u91wukix7Vv39ZXEaO0ynzgZy65CSoIf0KJo9U"
                                class="js-pop js-videoThumb js-videoThumbFlip thumb js-videoPreview lazy"
                width="150"
                 class="rotating" data-video-id="363214972" data-thumbs="16" data-path="https://ci.phncdn.com/videos/202010/23/363214972/original/(m=eWdTGgaaaa)(mh=kPwtPieqWzeLk_oC){index}.jpg"                    title="Hot babe tries fuck machine at college party" />

                                                                                                <div class="marker-overlays js-noFade">
                        <var class="duration">1:00</var>
                                                    <span class="hd-thumbnail">HD</span>
                                                                                                                                            </div>
                </a>
                            </div>
                                                        <div class="add-to-playlist-icon display-none">
                    <button type="button" data-title="Add to a Playlist" class="tooltipTrig open-playlist-link playlist-trigger" onclick="return false;" data-video-id="363214972"></button>
                </div>
                                        <div class="thumbnail-info-wrapper clearfix">
                <span class="title">
                                                                        <a href="/view_video.php?viewkey=ph5f9280abe0e56" title="Hot babe tries fuck machine at college party" class=""                                                                        >
                                Hot babe tries fuck machine at college party                            </a>
                                                            </span>
                                    <div class="videoUploaderBlock clearfix">

                        <div class="usernameWrap">
                                                            <a rel="nofollow" href="/users/zolanicole76"  title="zolanicole76">zolanicole76</a>                                                    </div>
                    </div>
                                <div class="videoDetailsBlock">
                                            <span class="views"><var>2.8K</var> views</span>
                        <div class="rating-container neutral">
                            <div class="main-sprite icon"></div>
                            <div class="value">82%</div>
                        </div>


                    <var class="added">22 hours ago</var>
                </div>

                            </div>
                    </div>

    </li>
            */

        // next page link <li class="page_next"><a href="/video?c=111&amp;page=2" class="orangeButton">Next <img class="pagination_arrow_right" src="https://di.phncdn.com/www-static/images/rightArrow.png"></a></li>




        data = data.replace(new RegExp("\r|\n", "g"), " ") // Qt doesn't have 's' flag to match newlines with .

        window.updateSessionHtml(data)

        var videos = []
        var videosRegex = new RegExp("<li\\s+.*?data-video-vkey=\"(.+?)\"\\s+.*?data-id=\"(.+?)\".*?>(.*?)</li>", "g")
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
