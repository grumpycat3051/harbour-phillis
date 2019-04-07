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

    property bool _reload: false
    property string prefix
    property string categoriesUrl
    property string title
    property real _targetImageHeight: Theme.itemSizeHuge
    readonly property real _targetCellWidth: width / settingDisplayCategoriesPerRow.value
    property var _filter: new RegExp(".*")
    property var _categories: []

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
                    _parseCategories(data, true)
                } else {
                    window.downloadError(url, error, errorMessage)
                }
                break
            }
        }
    }

    Connections {
        target: settingDisplayCategoriesPerRow
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
                load()
            }
        }

        onFlickingChanged: console.debug("flicking=" + flicking)
        onDraggingChanged: console.debug("dragging=" + dragging)

        PageHeader {
            id: header
            title: root.title
        }

        SearchField {
            id: search
            width: parent.width
            anchors.top: header.bottom
            visible: !parent.flicking
            //% "Filter"
            placeholderText: qsTrId("categories-page-filter-placeholder")
            onTextChanged: {
                if (text) {
                    var filter = text.replace(new RegExp("\\s+", "g"), ".*")
                    _filter = new RegExp(filter, "i")
                } else {
                    _filter = new RegExp(".*")
                }

                _applyFilter()
            }

            EnterKey.onClicked: {

            }
        }

        SilicaGridView {
            id: gridView
            clip: true
            //anchors.fill: parent
            width: parent.width
            anchors.top: search.visible ? search.bottom : parent.bottom
            anchors.bottom: parent.bottom
            model: model

            cellWidth: _targetCellWidth
            cellHeight: _targetImageHeight

            delegate: Component {
                ListItem {
//                    contentWidth: GridView.view.cellWidth
                    contentHeight: GridView.view.cellHeight
                    width: GridView.view.cellWidth
//                    height: GridView.view.cellHeight



                    Item {
                        //color: index % 2 ? "yellow" : "blue"
                        anchors.fill: parent

                        FramedImage {
                            source: category_thumbnail
                            anchors.centerIn: parent
                            width: parent.width
                            height: _targetImageHeight
                            topFrameHeight: 0
                            bottomFrameContent: Item {
                                width: parent.width
                                height: nameLabel.height

                                Label {
                                    id: nameLabel
                                    x: Theme.paddingSmall
                                    width: parent.width - 2*x
                                    anchors.verticalCenter: parent.verticalCenter
                                    truncationMode: TruncationMode.Fade
                                    text: category_name
                                    font.bold: true
                                }

                                Label {
                                    x: Theme.paddingSmall
                                    width: parent.width - 2*x
                                    horizontalAlignment: Text.AlignRight
                                    anchors.verticalCenter: parent.verticalCenter
                                    truncationMode: TruncationMode.Fade
                                    text: "(" + category_videos + ")"
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    font.bold: true
                                }
                            }
                        }
                    }

                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("VideosPage.qml"),
                                       {
                                           videosUrl: category_url,
                                           title: category_name
                                       })
                    }
                }
            }


            ViewPlaceholder {
                enabled: gridView.count === 0
                text: {
                    if (http.status === Http.StatusRunning) {
                        if (http.url === categoriesUrl) {
                            return "Categories are being loaded"
                        }
                    }

                    return ":/"
                }
            }

            Component.onCompleted: {
                currentIndex = -1
            }
        }
    }

    Component.onCompleted: load()

    function load() {
        if (_reload) {
            http.get(categoriesUrl)
        } else {
            var data = DownloadCache.load(categoriesUrl)
            if (data) {
                _parseCategories(data, false)
            } else {
                http.get(categoriesUrl)
            }
        }
    }

    function _parseCategories(data, storeInCache) {
        /* <li class="cat_pic" data-category="43">
        <div class="category-wrapper ">
            <a href="/video?c=43" alt="Vintage" class="js-mxp" data-mxptype="Category" data-mxptext="Vintage">
                <img
                    src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7"
                    data-thumb_url="https://ci.phncdn.com/is-static/images/categories/(m=qN4656TbetZD8zjadOf)(mh=K7L_N523xcwzRCFu)roku_43.jpg"
                    alt="Vintage"
                />
                                        </a>
            <h5>
                <a href="/video?c=43" class="js-mxp" data-mxptype="Category" data-mxptext="Vintage"><strong>Vintage</strong>
                    <span class="videoCount">
                        (<var>10,540</var>)
                    </span>
                </a>
                                        </h5>
                                </div>
    </li> */
        data = data.replace(new RegExp("\r|\n", "g"), " ") // Qt doesn't have 's' flag to match newlines with .
        window.updateSessionHtml(data)

        var categoriesRegex = new RegExp("<li\\s+class=\"cat_pic\"\\s+data-category=\"(\\d+)\">(.+?)</li>", "g")
        // src contains some gif stuff sometimes
        var categoryDataRegex = new RegExp("<img\\s+.*?data-thumb_url\\s*=\\s*\"(.+?)\"\\s+.*?alt\\s*=\\s*\"(.+?)\".*?/>.*?<span[^>]*>(.+?)</span>")
        var junkRegex = new RegExp("\\(|\\)|,|\\.|<.+?>|\\s+", "g")
        var categories = []
        for (var category; (category = categoriesRegex.exec(data)) !== null; ) {
//            console.debug(category)
            var categoryHtml = category[0]
            var categoryId = parseInt(category[1])
            var categoryData = categoryDataRegex.exec(categoryHtml)
            if (categoryData) {
                var categoryThumbnail = categoryData[1]
                var categoryName = categoryData[2]
                var videos = parseInt(categoryData[3].replace(junkRegex, ""))
                var name =
                categories.push({
                                    category_id: categoryId,
                                    category_url: Constants.baseUrl + root.prefix + "/video?c=" + categoryId,
                                    category_name: App.replaceHtmlEntities(categoryName),
                                    category_videos: videos,
                                    category_thumbnail: App.replaceHtmlEntities(categoryThumbnail),
                                })

            }
        }

        _categories = categories

        if (categories.length > 0) {
            _reload = false
            if (storeInCache) {
                DownloadCache.store(categoriesUrl, data, 3600)
            }

            thumbnailSizeDetector.source = categories[0].category_thumbnail
        } else {
            console.debug("data=" + data)
        }

        _applyFilter()
    }

    function _includedInFilter(str) {
        return _filter.exec(str) !== null
    }

    function _applyFilter() {
        model.clear()
        for (var i = 0; i < _categories.length; ++i) {
            var item = _categories[i]
            if (_includedInFilter(item.category_name)) {
                model.append(item)
            }
        }
    }
}
