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

    itemsPerRow: settingDisplayPornstarsPerRow.value
    property string pornstarsUrl
    property string title
    property bool _reload: false
    property int _page: 0
    property real _targetImageHeight: Theme.itemSizeHuge
    property bool _thumbnailLoaded: false
    property var _pornstars: []
    property bool isSearch: false

    on_TargetCellWidthChanged: _updateTargetImageHeight()
    on_ThumbnailLoadedChanged: _updateTargetImageHeight()

    function _updateTargetImageHeight() {
        if (_thumbnailLoaded) {
            _targetImageHeight = _targetCellWidth * thumbnailSizeDetector.sourceSize.height / thumbnailSizeDetector.sourceSize.width
        }
    }

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
                    _parse(data, url, true)
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

    Image {
        id: thumbnailSizeDetector
        visible: false
        onStatusChanged: {
            if (Image.Ready === status) {
                _thumbnailLoaded = true
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
                _pornstars = []
                _reload = true
                load()
            }
        }

        PushUpMenu {
            enabled: root._page >= 1
            MenuItem {
                //% "Load more"
                text: qsTrId("ph-push-up-menu-load-more")
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

                    FramedImage {
                        id: thumbnail
                        source: pornstar_thumbnail
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        topFrameHeight: 0
                        bottomFrameContent: Label {
                            x: Theme.paddingSmall
                            width: parent.width - 2*x
                            truncationMode: TruncationMode.Fade
                            text: pornstar_name
                            font.bold: true
                            horizontalAlignment: Text.AlignRight
                            anchors.verticalCenter: parent.verticalCenter
                            color: thumbnail.textColor
                        }
                    }

                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("VideosPage.qml"),
                                       {
                                           videosUrl: Scraper.videosUrlOf(pornstar_url),
                                           title: pornstar_name
                                       })
                    }
                }
            }


            ViewPlaceholder {
                enabled: gridView.count === 0
                text: {
                    if (http.status === Http.StatusRunning) {
                        //% "Pornstars are being loaded"
                        return qsTrId("ph-pornstars-page-view-placeholder-text-loading")
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
        var url = pornstarsUrl
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
        window.updateSessionHtml(data)
        var pornstars = Scraper.parsePornstars(data)
        var hasNextPage = Scraper.nextPage(data).hasNextPage
        console.debug("found " + pornstars.length + " performers, next page: " + hasNextPage)

        // a later page can repeat some of the earlier ones
        var known = {}
        for (var k = 0; k < _pornstars.length; ++k) {
            known[_pornstars[k].pornstar_url] = true
        }
        pornstars = pornstars.filter(function (p) { return !known[p.pornstar_url] })

        _pornstars = _pornstars.concat(pornstars)

        if (pornstars.length > 0) {

            if (storeInCache) {
                DownloadCache.store(url, data, 3600)
            }

            ++_page

            if (!hasNextPage) {
                _reload = false
                _page = -1
            }

            thumbnailSizeDetector.source = pornstars[0].pornstar_thumbnail
        } else {
            _page = -1
            var message = window.problemMessage(data)
            if (message) {
                window.notify(message)
            }
        }

        model.clear()
        for (var i = 0; i < _pornstars.length; ++i) {
            var item = _pornstars[i]
            model.append(item)
        }
    }

    function _makeUrl(baseUrl, newPart) {
        if (baseUrl.indexOf("?") >= 0) {
            return baseUrl + "&" + newPart
        }
        return baseUrl + "?" + newPart
    }
}
