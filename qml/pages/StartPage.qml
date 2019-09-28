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

    readonly property string categoriesUrl: Constants.baseUrl + "/categories"
    readonly property string prefix: settingGayOnly.value ? "/gay" : ""

    ListModel {
        id: videoModel
        ListElement {
            //% "Recommended"
            title: qsTrId("start-page-videos-recommended")
            relativeUrl: "/recommended"
            iconName: "idea.png"
        }

        ListElement {
            //% "Hottest"
            title: qsTrId("start-page-videos-hottest")
            relativeUrl: "/video?o=ht"
            iconName: "fire.png"
        }

        ListElement {
            //% "Most Viewed"
            title: qsTrId("start-page-videos-most-viewed")
            relativeUrl: "/video?o=mv"
            iconName: "graph.png"
        }

        ListElement {
            //% "Top Rated"
            title: qsTrId("start-page-videos-top-ratedmost-viewed")
            relativeUrl: "/video?o=tr"
            iconName: "thumbs-up-outlined.png"
        }

        ListElement {
            //% "Popular Homemade"
            title: qsTrId("start-page-videos-popular-homemade")
            relativeUrl: "/video?p=homemade&o=tr"
            iconName: "video-player.png"
        }
    }

    ListModel {
        id: categoryModel
        ListElement {
            //% "Popular"
            title: qsTrId("start-page-categories-popular")
            relativeUrl: "/categories"
            iconName: "heart-filled-white.png"
        }

        ListElement {
            //% "Alphabetical"
            title: qsTrId("start-page-categories-alphabetical")
            relativeUrl: "/categories?o=al"
            iconName: "sort.png"
        }

        ListElement {
            //% "Number of Videos"
            title: qsTrId("start-page-categories-no-videos")
            relativeUrl: "/categories?o=mv"
            iconName: "video-camera.png"
        }
    }

    ListModel {
        id: pornstarModel
        ListElement {
            //% "Most Popular"
            title: qsTrId("start-page-pornstars-most-popular")
            relativeUrl: "/pornstars"
            iconName: "heart-filled-white.png"
        }

        ListElement {
            //% "Top Trending"
            title: qsTrId("start-page-pornstars-top-trending")
            relativeUrl: "/pornstars?o=t"
            iconName: "up-arrow.png"
        }

        ListElement {
            //% "Most Viewed"
            title: qsTrId("start-page-pornstars-most-viewed")
            relativeUrl: "/pornstars?o=mv"
            iconName: "graph.png"
        }

        ListElement {
            //% "Most Subscribed"
            title: qsTrId("start-page-pornstars-most-subscribed")
            relativeUrl: "/pornstars?o=ms"
            iconName: "rss.png"
        }

//        ListElement {
//            //% "Alphabetical"
//            title: qsTrId("start-page-pornstars-alphabetical")
//            relativeUrl: "/pornstars?o=a"
//            iconName: "sort.png"
//        }

        ListElement {
            //% "Number of Videos"
            title: qsTrId("start-page-pornstars-no-videos")
            relativeUrl: "/pornstars?o=nv"
            iconName: "video-camera.png"
        }

//        ListElement {
//            //% "Male Pornstars"
//            title: qsTrId("start-page-pornstars-male")
//            relativeUrl: "/pornstars?gender=male"
//            iconName: "penis.png"
//        }
    }

    ListModel {
        id: userModel
    }

    Connections {
        target: window
        onUsernameChanged: _updateUserModel()
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


    SilicaFlickable {
        anchors.fill: parent

        VerticalScrollDecorator {}
        TopMenu {}

        // Tell SilicaFlickable the height of its content.
//        contentWidth: column.width
        contentHeight: column.height

        Column {
            id: column
            width: parent.width


            ExpandingSectionGroup {
                currentIndex: -1
                id: expandingGroup
                width: parent.width

                ExpandingSection {
                    //% "Videos"
                    title: qsTrId("start-page-videos-section-title")

                    content.sourceComponent: Column {
                        width: expandingGroup.width
                        Repeater {
                            model: videoModel.count
                            NavigationItem {
                                iconName: videoModel.get(index).iconName
                                title: videoModel.get(index).title

                                onClicked: {
                                    pageStack.push(
                                                Qt.resolvedUrl("VideosPage.qml"),
                                                {
                                                    videosUrl: Constants.baseUrl + root.prefix + videoModel.get(index).relativeUrl,
                                                    title: title
                                                })
                                }
                            }
                        }

                        SearchField {
                            width: parent.width
                            //% "Search"
                            placeholderText: qsTrId("start-page-search-placeholder")
                            EnterKey.onClicked: {
                                if (text) {
                                    pageStack.push(Qt.resolvedUrl("VideosPage.qml"),
                                                   {
                                                       title: text,
                                                       videosUrl: Constants.baseUrl + "/video/search?search=" + encodeURIComponent(text.toLowerCase())
                                                   })
                                }
                            }
                        }

//                        SearchField {
//                            width: parent.width
//                            //% "Search"
//                            placeholderText: qsTrId("start-page-search-placeholder")
//                            EnterKey.onClicked: {
//                                if (text) {
//                                    var url = Constants.baseUrl + "/video/search_autocomplete?pornstars=true&orientation=straight&alt=0&" + App.urlEncode({ q: text })
//                                    http.get(url)
//                                    //https://www.pornhub.com/video/search_autocomplete?pornstars=true&token=MTU2MzU1NDI5NVwIsVxo8VXICaCvKzKvQQ6N0KmPJipybpveKwVAB1vu0zIJTA0ZB1Dwg5_vLDe4cRNJG-jkXw1vikaHZIEgjwE.&orientation=straight&q=ab&alt=0
//                                }
//                            }
//                        }
                    }
                }

                ExpandingSection {
                    //% "Categories"
                    title: qsTrId("start-page-categories-section-title")

                    content.sourceComponent: Column {
                        width: expandingGroup.width
                        Repeater {
                            model: categoryModel.count
                            NavigationItem {
                                iconName: categoryModel.get(index).iconName
                                title: categoryModel.get(index).title
                                onClicked: {
                                    pageStack.push(
                                                Qt.resolvedUrl("CategoriesPage.qml"),
                                                {
                                                    categoriesUrl: Constants.baseUrl + root.prefix + categoryModel.get(index).relativeUrl,
                                                    title: title,
                                                    prefix: root.prefix
                                                })
                                }
                            }
                        }
                    }
                }

                ExpandingSection {
                    //% "Pornstars"
                    title: qsTrId("start-page-pornstars-section-title")

                    content.sourceComponent: Column {
                        width: expandingGroup.width

                        Repeater {
                            model: pornstarModel.count
                            NavigationItem {
                                iconName: pornstarModel.get(index).iconName
                                title: pornstarModel.get(index).title
                                onClicked: {
                                    pageStack.push(
                                                Qt.resolvedUrl("PornstarsPage.qml"),
                                                {
                                                    pornstarsUrl: Constants.baseUrl + root.prefix + pornstarModel.get(index).relativeUrl,
                                                    title: title
                                                })
                                }
                            }
                        }

                        SearchField {
                            width: parent.width
                            //% "Search"
                            placeholderText: qsTrId("start-page-search-placeholder")
                            EnterKey.onClicked: {
                                if (text) {
                                    pageStack.push(Qt.resolvedUrl("PornstarsPage.qml"),
                                                   {
                                                       pornstarsUrl: Constants.baseUrl + "/pornstars/search?search=" + encodeURIComponent(text.toLowerCase()),
                                                       title: text
                                                   })
                                }
                            }
                        }
                    }
                }

                ExpandingSection {
                    //% "My"
                    title: qsTrId("start-page-my-section-title")
                    visible: userModel.count > 0


                    content.sourceComponent: Column {
                        width: expandingGroup.width

                        Repeater {
                            model: userModel.count
                            NavigationItem {
                                iconName: userModel.get(index).iconName
                                title: userModel.get(index).title
                                onClicked: {
                                    pageStack.push(
                                                Qt.resolvedUrl("VideosPage.qml"),
                                                {
                                                    videosUrl: Constants.baseUrl + userModel.get(index).relativeUrl,
                                                    title: title
                                                })
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: _updateUserModel()

    function _updateUserModel() {
        userModel.clear()
        if (window.username) {
            userModel.append({
                                 //% "Favorites"
                                 title: qsTrId("start-page-user-videos-favorites"),
                                 relativeUrl: "/users/" + encodeURIComponent(window.username) + "/videos/favorites",
                                 iconName: "heart-filled-white.png",
                             })
        }
    }
}
