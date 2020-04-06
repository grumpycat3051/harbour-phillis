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

Page {
    id: root
    allowedOrientations: defaultAllowedOrientations

    property bool _reload: false
//    readonly property int pornstarsPerRow: settingDisplayPornstarsPerRow.value
//    readonly property int categoriesPerRow: settingDisplayCategoriesPerRow.value
    readonly property int pornstarsPerRow: 2
    readonly property int categoriesPerRow: 2
    property real _pornstarTargetImageHeight: Theme.itemSizeHuge
    property real _categoryTargetImageHeight: Theme.itemSizeHuge
    readonly property real _pornstarTargetCellWidth: width / pornstarsPerRow
    readonly property real _categoryTargetCellWidth: width / categoriesPerRow
    property bool _pornstarThumbnailLoaded: false
    property bool _categoryThumbnailLoaded: false

    on_PornstarTargetCellWidthChanged: _updatePornstarTargetImageHeight()
    on_PornstarThumbnailLoadedChanged: _updatePornstarTargetImageHeight()

    function _updatePornstarTargetImageHeight() {
        if (_pornstarThumbnailLoaded) {
            _pornstarTargetImageHeight = _pornstarTargetCellWidth * pornstarThumbnailSizeDetector.sourceSize.height / pornstarThumbnailSizeDetector.sourceSize.width
        }
    }

    on_CategoryTargetCellWidthChanged: _updateCategoryTargetImageHeight()
    on_CategoryThumbnailLoadedChanged: _updateCategoryTargetImageHeight()

    function _updateCategoryTargetImageHeight() {
        if (_categoryThumbnailLoaded) {
            _categoryTargetImageHeight = _categoryTargetCellWidth * categoryThumbnailSizeDetector.sourceSize.height / categoryThumbnailSizeDetector.sourceSize.width
        }
    }

    ListModel {
        id: pornstarModel
    }

    ListModel {
        id: categoryModel
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


    Image {
        id: pornstarThumbnailSizeDetector
        visible: false
        onStatusChanged: {
            if (Image.Ready === status) {
                _pornstarThumbnailLoaded = true
            }
        }
    }

    Image {
        id: categoryThumbnailSizeDetector
        visible: false
        onStatusChanged: {
            if (Image.Ready === status) {
                _categoryThumbnailLoaded = true
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: column.height


        VerticalScrollDecorator {}

        TopMenu {
            reloadCallback: function () {
                pornstarModel.clear()
                categoryModel.clear()
                _reload = true
                load()
            }
        }

        Column {
            id: column
            width: parent.width

            PageHeader {
                id: header
                //% "Recommended"
                title: qsTrId("ph-recommended-page-header")
            }


            SectionHeader {
                //% "Pornstars"
                text: qsTrId("ph-recommended-page-pornstars-section-header")
                visible: pornstarModel.count > 0
            }


            SilicaGridView {
                id: pornstarGridView
                quickScrollEnabled: false
                width: parent.width
                height: model ? _pornstarTargetImageHeight * Math.ceil(model.count / pornstarsPerRow) : 0
                model: pornstarModel

                cellWidth: _pornstarTargetCellWidth
                cellHeight: _pornstarTargetImageHeight


                delegate: Component {
                    ListItem {
                        contentHeight: GridView.view.cellHeight
                        width: GridView.view.cellWidth



                        FramedImage {
                            id: thumbnail
                            source: pornstar_thumbnail
                            fillMode: Image.PreserveAspectFit
                            anchors.fill: parent
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
                                               videosUrl: pornstar_url,
                                               title: pornstar_name
                                           })
                        }
                    }
                }

                Component.onCompleted: {
                    currentIndex = -1
                }
            }

            Item {
                width: parent.width
                height: Theme.paddingLarge
            }

            SectionHeader {
                //% "Categories"
                text: qsTrId("ph-recommended-page-categories-section-header")
                visible: categoryModel.count > 0
            }


            SilicaGridView {
                id: categoryGridView
                quickScrollEnabled: false
                width: parent.width
                height: model ? _categoryTargetImageHeight * Math.ceil(model.count / categoriesPerRow) : 0
                model: categoryModel

                cellWidth: _categoryTargetCellWidth
                cellHeight: _categoryTargetImageHeight


                delegate: Component {
                    ListItem {
                        contentHeight: GridView.view.cellHeight
                        width: GridView.view.cellWidth

                        FramedImage {
                            id: thumbnail
                            source: category_thumbnail
                            fillMode: Image.PreserveAspectFit
                            anchors.fill: parent
                            topFrameHeight: 0
                            bottomFrameContent: Label {
                                x: Theme.paddingSmall
                                width: parent.width - 2*x
                                truncationMode: TruncationMode.Fade
                                text: category_name
                                font.bold: true
                                horizontalAlignment: Text.AlignRight
                                anchors.verticalCenter: parent.verticalCenter
                                color: thumbnail.textColor
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

                Component.onCompleted: {
                    currentIndex = -1
                }
            }
        }
    }

    Component.onCompleted: load()

    function load() {
        // https://www.pornhub.com/recommended
        var url = Constants.baseUrl + "/recommended"
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
<div class="sectionWrapper recommendedPornstarsWrapper">
        <div class="sectionTitle">
            <div class="filters mainFilter float-right">
                <a href="/pornstars" class="float-right filterBtn" onclick="ga('send', 'event', 'homepage', 'pornstar');">See All</a>
            </div>
            <h1><a href="/pornstars" title="Recommended Pornstars">Recommended Pornstars</a></h1>
        </div>
        <ul class="popularSectionList">
                            <li>
                    <div class="wrap">
                        <a href="/pornstar/cristian-devil" onclick="ga('send', 'event', 'homepage', 'pornstar');">
                            <img src="https://ci.phncdn.com/pics/pornstars/000/004/859/(m=lciuhQditqM6G6WgaaaaGb_c)(mh=7croc8vT-VViB2zt)thumb_216611.jpg" title="Cristian Devil">
                                                        <span>Cristian Devil</span>
                        </a>
                    </div>
                </li>
                ...
<div class="reset"></div>
    </div>
            */

        data = data.replace(new RegExp("\r|\n", "g"), " ") // Qt doesn't have 's' flag to match newlines with .
        window.updateSessionHtml(data)
        var pornstars = []
        var categories = []
        var pornstarsRegex = new RegExp("<div\\s+class=[\"']sectionWrapper recommendedPornstarsWrapper[\"']>(.+?)</ul>")
        var pornstarDataRegex = new RegExp("<li>.*?<a\\s+.*?href=\"/pornstar/(.+?)\".*?>.*?<img\\s+.*?src=[\"'](.+?)[\"'].*?\\s+title=[\"'](.+?)[\"'].*?>", "g")

        var categoriesRegex = new RegExp("<div\\s+class=[\"']sectionWrapper recommendedCategoriesWrapper[\"']>(.+?)</ul>")
        var categoryDataRegex = new RegExp("<li>.*?<a\\s+.*?href=\"(.+?)\".*?>.*?<img\\s+.*?src=[\"'](.+?)[\"']\\s+alt=[\"'](.+?)[\"'].*?>", "g")


        var pornstarMatch = pornstarsRegex.exec(data)
        if (pornstarMatch) {
            var pornstarHtml = pornstarMatch[1]
            for (var pornstarMatch; (pornstarMatch = pornstarDataRegex.exec(pornstarHtml)) !== null; ) {
                var pornstarId = pornstarMatch[1]
                var thumbnail = pornstarMatch[2]
                var name = pornstarMatch[3]

                pornstars.push({
                    pornstar_id: pornstarId,
                    pornstar_url: Constants.baseUrl + "/pornstar/" + pornstarId,
                    pornstar_name: App.replaceHtmlEntities(name),
                    pornstar_thumbnail: App.replaceHtmlEntities(thumbnail)
                })
            }
        }

        var categoriesMatch = categoriesRegex.exec(data)
        if (categoriesMatch) {
            var categoryHtml = categoriesMatch[1]
            for (var categoryMatch; (categoryMatch = categoryDataRegex.exec(categoryHtml)) !== null; ) {
                var categoryUrl = categoryMatch[1]
                var thumbnail = categoryMatch[2]
                var name = categoryMatch[3]

                categories.push({
                    category_url: Constants.baseUrl + categoryUrl,
                    category_name: App.replaceHtmlEntities(name),
                    category_thumbnail: App.replaceHtmlEntities(thumbnail)
                })
            }
        }

        if (pornstars.length > 0 || categories.length > 0) {
            if (storeInCache) {
                DownloadCache.store(url, data, 3600)
            }

            if (pornstars.length > 0) {
                pornstarThumbnailSizeDetector.source = pornstars[0].pornstar_thumbnail
            }

            if (categories.length > 0) {
                categoryThumbnailSizeDetector.source = categories[0].category_thumbnail
            }

            pornstarModel.clear()
            if (pornstars.length > 0) {
                for (var i = 0; i < pornstars.length; ++i) {
                    var item = pornstars[i]
                    pornstarModel.append(item)
                }
            }

            categoryModel.clear()
            if (categories.length > 0) {
                for (var i = 0; i < categories.length; ++i) {
                    var item = categories[i]
                    categoryModel.append(item)
                }
            }
        } else {
            console.debug(data)
        }
    }
}
