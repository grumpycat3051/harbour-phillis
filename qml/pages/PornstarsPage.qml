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
import ".."

Page {
    id: root

    property string pornstarsUrl
    property string title
    property bool _reload: false
    property int _page: 0
    property real _targetImageHeight: Theme.itemSizeHuge
    readonly property real _targetCellWidth: width / settingDisplayPornstarsPerRow.value

    ListModel {
        id: model
    }


    Http {
        id: http

        onStatusChanged: {
            switch (status) {
            case Http.StatusCompleted:
                console.debug("completed error=" + error)
                if (Http.ErrorNone === error) {
                    _parse(data, url, true)
                } else {
                    window.downloadError(url, error, errorMessage)
                }
                break
            }
        }
    }

    Connections {
        target: settingDisplayPornstarsPerRow
        onValueChanged: {
            gridView.model = null
            gridView.model = model
        }
    }

    Image {
        id: thumbnailSizeDetector
        visible: false
        onStatusChanged: {
            if (Image.Ready === status) {
//                console.debug("image height: " + sourceSize.height)
                _targetImageHeight = _targetCellWidth * sourceSize.height / sourceSize.width
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
            enabled: root._page >= 1
            MenuItem {
                //% "Load more"
                text: qsTrId("bottom-menu-load-more")
                onClicked: http.get(_makeUrl(pornstarsUrl, "page=" + (root._page + 1)))
            }
        }

        SilicaGridView {
            id: gridView
            anchors.fill: parent
            model: model

            header: PageHeader {
                title: root.title
            }


            cellWidth: _targetCellWidth
            cellHeight: _targetImageHeight


            delegate: Component {
                ListItem {
                    contentHeight: GridView.view.cellHeight
                    width: GridView.view.cellWidth

                    Item {
                        //color: index % 2 ? "yellow" : "blue"
                        anchors.fill: parent

                        Image {
                            id: thumbnail
                            source: pornstar_thumbnail
                            anchors.centerIn: parent
                            fillMode: Image.PreserveAspectFit
                            width: parent.width
                            height: _targetImageHeight
                        }

                        Label {
                            id: nameLabel
                            x: Theme.paddingSmall
                            width: parent.width - 2*x
                            truncationMode: TruncationMode.Fade
                            text: pornstar_name
                            anchors.bottom: parent.bottom
                            font.bold: true
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("VideosPage.qml"),
                                       {
                                           videosUrl: pornstar_url,
                                           title: pornstar_name
                                       })
                    }
                }
            }


            ViewPlaceholder {
                enabled: gridView.count === 0
                text: {
                    if (http.status === Http.StatusRunning) {
                        return "Pornstars are being loaded"
                    }

                    return ":/"
                }
            }

            Component.onCompleted: {
                currentIndex = -1
            }
        }
    }

    BusyIndicator {
        size: BusyIndicatorSize.Large
        anchors.centerIn: parent
        visible: running
        running: gridView.count > 0 &&
                 http.status === Http.StatusRunning &&
                 http.url.indexOf(pornstarsUrl) >= 0
    }

    Component.onCompleted: load()

    on_PageChanged: {
        console.debug("_page="+_page)
    }

    function load() {
        _page = 0
        var url = _makeUrl(pornstarsUrl, "page=" + (_page + 1))
        if (_reload) {
            http.get(url)
        } else {
            var data = DownloadCache.load(url)
            if (data) {
                _parse(data, url, false)
            } else {
                http.get(url)
            }
        }
    }

    function _parse(data, url, storeInCache) {

        /*
<li>
    <div class="wrap">
        <div class="subscribe-to-pornstar-icon display-none">
            <button type="button" data-title="Subscribe to Pornstar" class="tooltipTrig" onclick="return false;" ><span></span></button>
        </div>
        <a class="js-mxp" data-mxptype="Pornstar" data-mxptext="Alexis Texas" href="/pornstar/alexis-texas">
                                    <span class="pornstar_label">
                <span class="title-album">Rank:
                    <span class="rank_number">
                        13					</span>

                    <span class='icon rank-down'></span>				</span>
            </span>
            <img
                data-thumb_url="https://di.phncdn.com/pics/pornstars/000/000/118/(m=lciyeNbOb_c)(mh=HCqIOnRDqt5A2DoL)thumb_13291.jpg"
                src="https://di.phncdn.com/pics/pornstars/000/000/118/(m=lciyeNbOb_c)(mh=HCqIOnRDqt5A2DoL)thumb_13291.jpg"
                alt="Alexis Texas"
            />
                                                </a>
        <div class="thumbnail-info-wrapper">
            <a href="/pornstar/alexis-texas" class="title js-mxp" data-mxptype="Pornstar" data-mxptext="Alexis Texas" >Alexis Texas</a>
            <span class="videosNumber">1849 Videos				392M views </span>
        </div>
    </div>
</li>
            */

        // next page link <li class="page_next"><a href="/video?c=111&amp;page=2" class="orangeButton">Next <img class="pagination_arrow_right" src="https://di.phncdn.com/www-static/images/rightArrow.png"></a></li>

        data = data.replace(new RegExp("\r|\n", "g"), " ") // Qt doesn't have 's' flag to match newlines with .
        window.updateSessionHtml(data)
        var pornstars = []
        var pornstarsRegex = new RegExp("<li>\\s*<div class=\"wrap\">\\s*<div class=\"subscribe-to-pornstar-icon display-none\">(.+?)</li>", "g")
        var pornstarDataRegex = new RegExp("<a\\s+.*?href=\"/pornstar/(.+?)\".*?>.*?<span\\s+class=\"rank_number\">\\s*(\\d+)\\s*</span>.*?<img\\s+.*?data-thumb_url\\s*=\\s*\"(.+?)\"\\s+.*?alt\\s*=\\s*\"(.+?)\".*?/>.*?<span\\s+class=\"videosNumber\">\\s*(\\d+)\\s*Videos\\s+(\\S+)\\s+views\\s*</span>")
        var junkRegex = new RegExp("\\(|\\)|,|\\.|<.+?>|\\s+", "g")

        var nextRegex = new RegExp("<li\\s+class=\"page_next\">\\s*<a href=\"(.+?)\".*?>.*?</li>")
        for (var pornstar; (pornstar = pornstarsRegex.exec(data)) !== null; ) {
//            console.debug(category)
            var pornstarHtml = pornstar[1]
            var pornstarData = pornstarDataRegex.exec(pornstarHtml)
            if (pornstarData) {
                var pornstarId = pornstarData[1]
                var rank = parseInt(pornstarData[2])
                var thumbnail = pornstarData[3]
                var name = pornstarData[4]
                var videos = parseInt(pornstarData[5])
                var views = pornstarData[6]
                pornstars.push({
                                    pornstar_id: pornstarId,
                                    pornstar_url: Constants.baseUrl + "/pornstar/" + pornstarId,
                                    pornstar_name: App.replaceHtmlEntities(name),
                                    pornstar_videos: videos,
                                    pornstar_views: views,
                                    pornstar_thumbnail: App.replaceHtmlEntities(thumbnail),
                                    pornstar_rank: rank
                                })

            }
        }

        var hasNextPage = !!nextRegex.exec(data)

        if (pornstars.length > 0) {

            if (storeInCache) {
                DownloadCache.store(url, data, 3600)
            }

            ++_page

            if (!hasNextPage) {
                _reload = false
                _page = -1
            }

//            console.debug("adding " + (videos.length-videosToSkip) + " videos")
            thumbnailSizeDetector.source = pornstars[0].pornstar_thumbnail

            for (var i = 0; i < pornstars.length; ++i) {
                var item = pornstars[i]
                model.append(item)
            }
        } else {
            console.debug(data)
        }
    }

    function _makeUrl(baseUrl, newPart) {
        if (baseUrl.indexOf("?") >= 0) {
            return baseUrl + "&" + newPart
        }
        return baseUrl + "?" + newPart
    }
}
