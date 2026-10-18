/* The MIT License (MIT)
 *
 * Copyright (c) 2026 Kieren Nicolas
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
import "../Scraper.js" as Scraper

// Loads the pages the app reads and reports what it finds in them, so a change on the
// website can be pinned down. The report has counts, status codes and the structure of the
// markup where something wasn't found; no titles, names, tokens or passwords.
Page {
    id: root
    allowedOrientations: defaultAllowedOrientations

    property string report: ""
    readonly property bool running: _step >= 0
    property var _steps: []
    property int _step: -1
    property string _videoPageUrl
    property string _getMediaUrl
    property string _fileUrl

    Http {
        id: http
        onStatusChanged: {
            if (status === Http.StatusCompleted && root._step >= 0) {
                root._finishStep()
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        PullDownMenu {
            busy: root.running
            MenuItem {
                //% "Copy report"
                text: qsTrId("ph-site-check-copy")
                enabled: !root.running && root.report.length > 0
                onClicked: Clipboard.text = root.report
            }
            MenuItem {
                //% "Check again"
                text: qsTrId("ph-site-check-again")
                enabled: !root.running
                onClicked: root.start()
            }
        }

        Column {
            id: column
            width: parent.width

            PageHeader {
                //% "Website check"
                title: qsTrId("ph-site-check-header")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
                //% "Loads the pages the app reads and reports what it finds. The report has no titles, names or passwords. Copy it from the pull-down menu."
                text: qsTrId("ph-site-check-explanation")
            }

            Item { width: 1; height: Theme.paddingLarge }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.WrapAnywhere
                font.pixelSize: Theme.fontSizeTiny
                textFormat: Text.PlainText
                text: root.report
            }
        }

        VerticalScrollDecorator {}
    }

    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: root.running && root.report.length < 200
    }

    Component.onCompleted: start()

    // the address without query values (they can hold tokens)
    function _shortUrl(url) {
        return String(url || "").replace(/=([^&#]*)/g, "=…")
    }

    function _line(text) {
        report += text + "\n"
    }

    function _yes(value) {
        return value ? "yes" : "no"
    }

    function _pageSummary(data) {
        var session = Scraper.isLoggedIn(data) ? "logged in" : "logged out"
        var problem = Scraper.pageProblem(data)
        _line("title: " + (Scraper.pageTitle(data).length ? "present" : "none") + ", " + session + (problem ? ", PROBLEM: " + problem : ""))
    }

    function _videoListCheck(data, keepFirst) {
        var list = Scraper.parseVideoList(data)
        _line("videos: " + list.videos.length + " (list: " + (list.container || "whole page") + "), next page: " + _yes(list.hasNextPage))
        if (list.videos.length) {
            var v = list.videos[0]
            _line("first video has title " + _yes(v.video_title) + ", thumbnail " + _yes(v.video_thumbnail)
                  + ", length " + _yes(v.video_length) + ", views " + _yes(v.video_views)
                  + ", rating " + _yes(v.video_rating >= 0) + ", added " + _yes(v.video_added))
            if (keepFirst) {
                _videoPageUrl = v.video_url
            }
        } else {
            _line("markup: " + (Scraper.skeletonAround(data, /data-video-vkey|videoblock|viewkey=/, 300, 3000) || "no video links"))
        }
    }

    function start() {
        report = ""
        _videoPageUrl = ""
        _getMediaUrl = ""
        _fileUrl = ""
        _line(App.displayName + " " + App.version + " website check, " + new Date().toISOString())
        _line("app login: " + (window.isUserLoggedIn ? "logged in" : (window.hasLoginData ? "account set, logged out" : "no account set")))

        var base = Constants.baseUrl
        var mediaHeaders = function (extra) {
            var headers = { "Range": "bytes=0-1023" }
            if (extra) {
                headers["Referer"] = base + "/"
                headers["Origin"] = base
            }
            return headers
        }

        _steps = [
            {
                name: "Home page",
                url: base + "/",
                check: function (data) {
                    _pageSummary(data)
                    _line("login token: " + _yes(Scraper.loginFields(data).token))
                    _videoListCheck(data, false)
                }
            },
            {
                name: "Login page",
                url: base + "/login",
                check: function (data) {
                    _pageSummary(data)
                    var fields = Scraper.loginFields(data)
                    _line("login form posts to authenticate: " + _yes(/<form\b[^>]*authenticate/i.test(data)))
                    _line("hidden fields: " + (Object.keys(fields).join(", ") || "none"))
                    if (!fields.token) {
                        _line("markup: " + (Scraper.skeletonAround(data, /<form\b[^>]*(?:login|signin|authenticate)/i, 0, 3000) || "no login form"))
                    }
                }
            },
            {
                name: "Hottest videos",
                url: base + "/video?o=ht",
                check: function (data) {
                    _pageSummary(data)
                    _videoListCheck(data, true)
                }
            },
            {
                name: "Video search",
                url: base + "/video/search?search=test",
                check: function (data) {
                    _pageSummary(data)
                    _videoListCheck(data, !_videoPageUrl)
                }
            },
            {
                name: "Recommended",
                url: base + "/recommended",
                check: function (data) {
                    _pageSummary(data)
                    _videoListCheck(data, false)
                }
            },
            {
                name: "Categories",
                url: base + "/categories",
                check: function (data) {
                    _pageSummary(data)
                    var categories = Scraper.parseCategories(data, "")
                    _line("categories: " + categories.length)
                    if (categories.length) {
                        var c = categories[0]
                        _line("first has id " + _yes(c.category_id >= 0) + ", thumbnail " + _yes(c.category_thumbnail) + ", video count " + _yes(c.category_videos > 0))
                    } else {
                        _line("markup: " + (Scraper.skeletonAround(data, /catPic|data-category|href="\/categories\//, 300, 3000) || "no category links"))
                    }
                }
            },
            {
                name: "Pornstars",
                url: base + "/pornstars",
                check: function (data) {
                    _pageSummary(data)
                    var list = Scraper.parsePornstars(data)
                    _line("performers: " + list.length + ", next page: " + _yes(Scraper.nextPage(data).hasNextPage))
                    if (list.length) {
                        var p = list[0]
                        _line("first has thumbnail " + _yes(p.pornstar_thumbnail) + ", rank " + _yes(p.pornstar_rank > 0) + ", videos " + _yes(p.pornstar_videos > 0) + ", views " + _yes(p.pornstar_views))
                    } else {
                        _line("markup: " + (Scraper.skeletonAround(data, /performerCard|href="\/pornstar\//, 300, 3000) || "no performer links"))
                    }
                }
            },
            {
                name: "Video page",
                url: function () { return _videoPageUrl },
                check: function (data) {
                    _pageSummary(data)
                    var page = Scraper.parseVideoPage(data)
                    var streams = page.formats.map(function (f) { return f.format + " " + f.quality }).join(", ")
                    _line("flashvars: " + _yes(/var\s+flashvars_/.test(data)) + ", streams: " + (streams || "none") + ", get_media: " + page.getMediaUrls.length)
                    _line("votes " + _yes(page.upVotes >= 0) + ", rating token " + _yes(page.ratingToken) + ", uploader " + _yes(page.model.url)
                          + ", categories " + page.categories.length + ", performers " + page.pornstars.length + ", tags " + page.tags.length)
                    if (page.unavailableMessage) {
                        _line("unavailable: " + page.unavailableMessage)
                    }
                    if (!page.formats.length && !page.getMediaUrls.length) {
                        _line("markup: " + (Scraper.skeletonAround(data, /flashvars|mediaDefinitions|id="player"/, 0, 3000) || "no player"))
                    }
                    _getMediaUrl = page.getMediaUrls.length ? page.getMediaUrls[0] : ""
                    _fileUrl = page.formats.length ? page.formats[0].url : ""
                }
            },
            {
                name: "get_media",
                url: function () { return _getMediaUrl },
                headers: function () {
                    return {
                        "Referer": _videoPageUrl,
                        "Accept": "application/json, text/javascript, */*; q=0.01",
                        "X-Requested-With": "XMLHttpRequest",
                    }
                },
                check: function (data) {
                    var files = Scraper.parseMediaList(data)
                    _line("files: " + (files.map(function (f) { return f.format + " " + f.quality }).join(", ") || "none"))
                    if (files.length) {
                        _fileUrl = files[0].url
                    } else {
                        _line("answer starts: " + _shortUrl(data.substring(0, 300)))
                    }
                }
            },
            {
                name: "Video file, with the site as Referer and Origin",
                url: function () { return _fileUrl },
                headers: function () { return mediaHeaders(true) },
                check: function (data) {}
            },
            {
                name: "Video file, without them",
                url: function () { return _fileUrl },
                headers: function () { return mediaHeaders(false) },
                check: function (data) {}
            },
        ]
        _step = -1
        _next()
    }

    function _next() {
        while (++_step < _steps.length) {
            var step = _steps[_step]
            var url = typeof step.url === "function" ? step.url() : step.url
            if (url) {
                _line("\n== " + step.name)
                http.get(url, step.headers ? step.headers() : {})
                return
            }
            _line("\n== " + step.name + ": skipped, nothing to load")
        }
        _step = -1
        _line("\ndone")
    }

    function _finishStep() {
        var step = _steps[_step]
        var data = http.data || ""
        var error = http.error === Http.ErrorNone ? "" : ", error: " + String(http.errorMessage).replace(/https?:\/\/\S+/g, _shortUrl)
        _line("[" + http.httpStatusCode + "] " + _shortUrl(http.finalUrl || http.url) + ", " + data.length + " characters" + error)
        try {
            step.check(data)
        } catch (e) {
            _line("check failed: " + e)
        }
        _next()
    }
}
