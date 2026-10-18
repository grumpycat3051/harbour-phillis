.pragma library
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

// Reads the website's pages. The markup changes from time to time, so each value is looked up
// on its own (by attribute or class name, with fallbacks for older markup) instead of with one
// expression per item that stops matching as soon as anything in the item moves.
//
// Plain ES5 only: this runs in the JavaScript engine of Qt 5.6.

var baseUrl = "https://www.pornhub.com"

// ------------------------------------------------------------------------------------------
// text and markup helpers

var _namedEntities = { amp: "&", lt: "<", gt: ">", quot: "\"", apos: "'", nbsp: " " }

function decodeEntities(s) {
    if (!s) {
        return ""
    }
    return String(s).replace(/&(#[xX][0-9a-fA-F]+|#\d+|[a-zA-Z]+);/g, function (m, e) {
        if (e.charAt(0) === "#") {
            var hex = e.charAt(1) === "x" || e.charAt(1) === "X"
            var code = hex ? parseInt(e.substring(2), 16) : parseInt(e.substring(1), 10)
            if (isNaN(code) || code <= 0 || code > 0x10FFFF) {
                return m
            }
            if (code > 0xFFFF) {
                code -= 0x10000
                return String.fromCharCode(0xD800 + (code >> 10), 0xDC00 + (code & 0x3FF))
            }
            return String.fromCharCode(code)
        }
        var name = e.toLowerCase()
        return _namedEntities.hasOwnProperty(name) ? _namedEntities[name] : m
    })
}

// text of a piece of markup: tags removed, entities decoded, white space collapsed
function cleanText(html) {
    if (!html) {
        return ""
    }
    var text = String(html)
        .replace(/<script\b[\s\S]*?<\/script>/gi, " ")
        .replace(/<style\b[\s\S]*?<\/style>/gi, " ")
        .replace(/<[^>]*>/g, " ")
    return decodeEntities(text).replace(/\s+/g, " ").trim()
}

var _attrPatterns = {}

// value of attribute name in an opening tag, entities decoded; "" if it isn't there
function attr(tag, name) {
    if (!tag || tag.indexOf(name) < 0) {
        return ""
    }
    var re = _attrPatterns[name]
    if (!re) {
        re = _attrPatterns[name] = new RegExp("\\s" + name + "\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)'|([^\\s\"'>]+))", "i")
    }
    var m = re.exec(tag)
    if (!m) {
        return ""
    }
    return decodeEntities(m[1] || m[2] || m[3] || "")
}

function hasAttr(tag, name) {
    return !!tag && tag.indexOf(name) >= 0 && new RegExp("\\s" + name + "(?:\\s*=|[\\s/>])", "i").test(tag)
}

function hasClass(tag, className) {
    if (!tag || tag.indexOf(className) < 0) {
        return false
    }
    return attr(tag, "class").split(/\s+/).indexOf(className) >= 0
}

// the first opening tag of the given element name in html, or ""
function firstTag(html, tagName, predicate) {
    var re = new RegExp("<" + tagName + "\\b[^>]*>", "gi")
    var m
    while ((m = re.exec(html || "")) !== null) {
        if (!predicate || predicate(m[0])) {
            return m[0]
        }
    }
    return ""
}

var _voidElements = /^(?:area|base|br|col|embed|hr|img|input|link|meta|source|track|wbr)$/i

// [{ tag, index, inner }] for each element in html whose name matches tagName (a name or a
// pattern) and whose opening tag satisfies predicate; inner is the markup up to the matching
// closing tag (elements of the same name nested inside are skipped over)
function elements(html, tagName, predicate) {
    var result = []
    html = html || ""
    var re = new RegExp("<(" + tagName + ")\\b[^>]*>", "gi")
    var m
    while ((m = re.exec(html)) !== null) {
        if (predicate && !predicate(m[0])) {
            continue
        }
        var innerStart = m.index + m[0].length
        var inner = ""
        if (!_voidElements.test(m[1]) && m[0].charAt(m[0].length - 2) !== "/") {
            inner = html.substring(innerStart, _closingTagIndex(html, m[1], innerStart))
        }
        result.push({ tag: m[0], index: m.index, inner: inner })
    }
    return result
}

function _closingTagIndex(html, tagName, from) {
    var re = new RegExp("<(/?)" + tagName + "\\b[^>]*>", "gi")
    re.lastIndex = from
    var depth = 1
    var m
    while ((m = re.exec(html)) !== null) {
        if (m[1]) {
            if (--depth === 0) {
                return m.index
            }
        } else if (m[0].charAt(m[0].length - 2) !== "/") {
            ++depth
        }
    }
    return html.length
}

// html from the start of the element holding the first marker found (in the given order of
// preference); the whole page if none is there
function _sliceFrom(html, markers) {
    for (var i = 0; i < markers.length; ++i) {
        var index = html.indexOf(markers[i])
        if (index >= 0) {
            var start = html.lastIndexOf("<", index)
            return { html: html.substring(start >= 0 ? start : index), marker: markers[i] }
        }
    }
    return { html: html, marker: "" }
}

// pieces of html, each starting at an <li> tag that satisfies isStart and running to the
// next such tag (or at most maxLength characters)
function _itemBlocks(html, isStart, maxLength) {
    var starts = []
    var re = /<li\b[^>]*>/gi
    var m
    while ((m = re.exec(html)) !== null) {
        if (isStart(m[0])) {
            starts.push({ index: m.index, tag: m[0] })
        }
    }
    var blocks = []
    for (var i = 0; i < starts.length; ++i) {
        var end = i + 1 < starts.length ? starts[i + 1].index : html.length
        end = Math.min(end, starts[i].index + maxLength)
        blocks.push({ tag: starts[i].tag, html: html.substring(starts[i].index, end) })
    }
    return blocks
}

function absoluteUrl(url) {
    url = (url || "").trim()
    if (!url) {
        return ""
    }
    if (/^https?:\/\//i.test(url)) {
        return url
    }
    if (url.indexOf("//") === 0) {
        return "https:" + url
    }
    if (url.charAt(0) === "/") {
        return baseUrl + url
    }
    return baseUrl + "/" + url
}

function _isUsableLink(href) {
    return !!href && href !== "#" && !/^javascript:/i.test(href)
}

// thumbnail address of an <img> tag; lazy-loading images keep the real one in a data attribute
function imageUrl(imgTag) {
    var names = ["data-mediumthumb", "data-thumb_url", "data-src", "data-image", "data-original", "data-poster", "src"]
    for (var i = 0; i < names.length; ++i) {
        var value = attr(imgTag, names[i])
        if (value && value.indexOf("data:") !== 0 && value.indexOf("{") < 0) {
            return absoluteUrl(value)
        }
    }
    return ""
}

// "1,234" -> 1234, "2.8K" -> 2800, "1.5M" -> 1500000; NaN if there is no number
function parseCount(text) {
    var m = /(\d[\d,.]*)\s*([KkMmBb]?)/.exec(text || "")
    if (!m) {
        return NaN
    }
    var digits = m[1]
    var factor = { k: 1e3, m: 1e6, b: 1e9 }[m[2].toLowerCase()] || 1
    if (factor === 1) {
        return parseInt(digits.replace(/[,.]/g, ""), 10)
    }
    return Math.round(parseFloat(digits.replace(/,/g, "")) * factor)
}

// text of the first element whose class list contains className
function _textOfClass(html, className, tagName) {
    var found = elements(html, tagName || "[a-zA-Z][a-zA-Z0-9]*", function (tag) { return hasClass(tag, className) })
    return found.length ? cleanText(found[0].inner) : ""
}

// ------------------------------------------------------------------------------------------
// page state

// "geo" when the content is blocked for the visitor's country, "challenge" for a bot check
// that needs a browser, "" otherwise
function pageProblem(html) {
    html = html || ""
    if (/class\s*=\s*["']geoBlocked["']|>\s*This content is unavailable in your country|is not available in your (?:country|region)/i.test(html)) {
        return "geo"
    }
    if (/document\.cookie\s*=\s*["']RNKEY=|<body\b[^>]+\bonload\s*=\s*["']go\(\)|\/cdn-cgi\/challenge-platform\/|<title>\s*Just a moment\.\.\.\s*<\/title>/i.test(html)) {
        return "challenge"
    }
    return ""
}

function pageTitle(html) {
    var m = /<title\b[^>]*>([\s\S]*?)<\/title>/i.exec(html || "")
    return m ? cleanText(m[1]) : ""
}

// the message the site shows instead of a removed, private or disabled video; "" if none
function videoUnavailableMessage(html) {
    var found = elements(html, "div", function (tag) {
        return hasClass(tag, "removed") || hasClass(tag, "userMessageSection")
    })
    if (found.length) {
        return cleanText(found[0].inner)
    }
    found = elements(html, "section", function (tag) { return hasClass(tag, "noVideo") })
    if (found.length) {
        return cleanText(found[0].inner)
    }
    return ""
}

// ------------------------------------------------------------------------------------------
// session

function isLoggedIn(html) {
    return /id\s*=\s*["']profileMenuDropdown["']|class\s*=\s*["'][^"']*\bph-icon-logout\b|\/user\/logout\?token=/.test(html || "")
}

function logoutToken(html) {
    var m = /\/user\/logout\?token=([^"'&\s<>]+)/.exec(html || "")
    return m ? decodeEntities(m[1]) : ""
}

function username(html) {
    html = html || ""
    var userLink = /href\s*=\s*["'](?:https?:\/\/[^"'\/]+)?\/(?:users|model)\/([^"'\/?#]+)/
    var index = html.search(/id\s*=\s*["']profileMenu|class\s*=\s*["'][^"']*\bprofile\b/)
    if (index >= 0) {
        var m = userLink.exec(html.substr(index, 6000))
        if (m) {
            return decodeURIComponent(m[1])
        }
    }
    return ""
}

// the fields of the login form (token, redirect, ...) without the user's name and password
function loginFields(html) {
    html = html || ""
    var forms = elements(html, "form", function (tag) {
        return /authenticate|login|signin/i.test(attr(tag, "action") + " " + attr(tag, "id") + " " + attr(tag, "class") + " " + attr(tag, "name"))
    })
    var fields = {}
    var source = forms.length ? forms[0].inner : ""
    var inputs = elements(source, "input", function (tag) { return attr(tag, "type").toLowerCase() === "hidden" })
    for (var i = 0; i < inputs.length; ++i) {
        var name = attr(inputs[i].tag, "name")
        if (name) {
            fields[name] = attr(inputs[i].tag, "value")
        }
    }
    if (!fields.token) {
        // no login form on this page; the token is also in the page's sign-in pop-up
        var token = firstTag(html, "input", function (tag) { return attr(tag, "name") === "token" && !!attr(tag, "value") })
        if (token) {
            fields.token = attr(token, "value")
            var redirect = firstTag(html, "input", function (tag) { return attr(tag, "name") === "redirect" })
            if (redirect) {
                fields.redirect = attr(redirect, "value")
            }
        }
    }
    return fields
}

// fields as an application/x-www-form-urlencoded body; unlike QUrlQuery this also encodes
// "+", "%", "&" and "=" in the values (which can be in a password)
function formEncode(fields) {
    var parts = []
    for (var name in fields) {
        if (fields.hasOwnProperty(name)) {
            var value = fields[name] === undefined || fields[name] === null ? "" : String(fields[name])
            parts.push(encodeURIComponent(name).replace(/%20/g, "+") + "=" + encodeURIComponent(value).replace(/%20/g, "+"))
        }
    }
    return parts.join("&")
}

// the body of the login request: the form's own fields plus the account
function loginBody(fields, account, password) {
    var body = {}
    for (var name in fields) {
        if (fields.hasOwnProperty(name)) {
            body[name] = fields[name]
        }
    }
    // the form's name field has been called "username" and "email"; it takes either
    body.username = account
    body.email = account
    body.password = password
    body.remember_me = 1
    if (!body.hasOwnProperty("from")) {
        body.from = "pc_login_modal_:show"
    }
    return formEncode(body)
}

// { success, message } from the answer to a login request
function parseLoginResponse(text) {
    try {
        var json = JSON.parse(text)
        var ok = json.success === "1" || json.success === 1 || json.success === true || json.success === "true"
        return { success: ok, message: cleanText(json.message || "") }
    } catch (e) {
        return { success: false, message: "" }
    }
}

// ------------------------------------------------------------------------------------------
// video lists

var _videoListMarkers = [
    "id=\"videoSearchResult\"",
    "id=\"videoCategory\"",
    "recommendedVideosContainer",
    "id=\"mostRecentVideosSection\"",
    "id=\"videoFavoritesListSection\"",
    "id=\"moreData\"",
    "videoUList",
]

function _isVideoItemTag(tag) {
    return hasAttr(tag, "data-video-vkey") || hasClass(tag, "videoblock") || hasClass(tag, "pcVideoListItem")
}

function _videoFromBlock(block) {
    var html = block.html
    var thumbLink = firstTag(html, "a", function (tag) { return hasClass(tag, "linkVideoThumb") })
        || firstTag(html, "a", function (tag) { return attr(tag, "href").indexOf("viewkey=") >= 0 })
    var href = attr(thumbLink, "href")
    if (thumbLink && !_isUsableLink(href)) {
        return null // premium only, can't be watched without a subscription
    }

    var viewKey = attr(block.tag, "data-video-vkey")
    if (!viewKey) {
        var keyMatch = /viewkey=([0-9a-zA-Z]+)/.exec(href || html)
        viewKey = keyMatch ? keyMatch[1] : ""
    }
    if (!viewKey) {
        return null
    }

    var img = firstTag(html, "img")
    var title = attr(thumbLink, "title") || attr(thumbLink, "data-title") || attr(img, "alt") || attr(img, "title")
        || _textOfClass(html, "title")

    var rating = NaN
    var ratingMatch = /class\s*=\s*["'][^"']*\bvalue\b[^"']*["'][^>]*>\s*(\d+)\s*%/.exec(html)
        || /class\s*=\s*["'][^"']*\brating-container\b[\s\S]{0,300}?(\d+)\s*%/.exec(html)
    if (ratingMatch) {
        rating = parseInt(ratingMatch[1], 10)
    }

    var views = ""
    var viewsMatch = /class\s*=\s*["'][^"']*\bviews\b[^"']*["'][^>]*>\s*<var\b[^>]*>([^<]*)<\/var>/.exec(html)
    if (viewsMatch) {
        views = cleanText(viewsMatch[1])
    } else {
        views = _textOfClass(html, "views").replace(/\s*views?\s*$/i, "")
    }

    return {
        video_url: baseUrl + "/view_video.php?viewkey=" + viewKey,
        video_viewkey: viewKey,
        video_id: attr(block.tag, "data-video-id") || attr(block.tag, "data-id") || attr(img, "data-video-id") || viewKey,
        video_title: title,
        video_thumbnail: imageUrl(img),
        video_length: _textOfClass(html, "duration"),
        video_views: views,
        video_rating: isNaN(rating) ? -1 : rating,
        video_added: _textOfClass(html, "added"),
    }
}

// { videos, hasNextPage, nextUrl, container } for a page that lists videos
function parseVideoList(html) {
    html = html || ""
    var scope = _sliceFrom(html, _videoListMarkers)
    var blocks = _itemBlocks(scope.html, _isVideoItemTag, 8000)
    var videos = []
    var seen = {}
    for (var i = 0; i < blocks.length; ++i) {
        var video = _videoFromBlock(blocks[i])
        if (video && !seen[video.video_viewkey]) {
            seen[video.video_viewkey] = true
            videos.push(video)
        }
    }
    var next = nextPage(html)
    return { videos: videos, hasNextPage: next.hasNextPage, nextUrl: next.url, container: scope.marker }
}

// { hasNextPage, url } from a page's pagination
function nextPage(html) {
    var items = elements(html, "li", function (tag) { return hasClass(tag, "page_next") })
    if (items.length) {
        var link = firstTag(items[0].inner, "a")
        var href = attr(link, "href")
        var usable = !hasClass(items[0].tag, "disabled") && _isUsableLink(href)
        return { hasNextPage: usable, url: usable ? absoluteUrl(href) : "" }
    }
    var next = firstTag(html, "link", function (tag) { return attr(tag, "rel").toLowerCase() === "next" })
    if (next && attr(next, "href")) {
        return { hasNextPage: true, url: absoluteUrl(attr(next, "href")) }
    }
    if (/<button\b[^>]*\bid\s*=\s*["']moreDataBtn["']/.test(html)) {
        return { hasNextPage: true, url: "" }
    }
    return { hasNextPage: false, url: "" }
}

// ------------------------------------------------------------------------------------------
// cards: categories and performers

// cards for every link whose address matches hrefPattern; a card's picture and name may come
// from different links to the same address
function _cardsByLink(html, hrefPattern) {
    var cards = []
    var byUrl = {}
    var links = elements(html, "a", function (tag) { return hrefPattern.test(attr(tag, "href")) })
    for (var i = 0; i < links.length; ++i) {
        var link = links[i]
        var url = absoluteUrl(attr(link.tag, "href"))
        var card = byUrl[url]
        if (!card) {
            card = byUrl[url] = { url: url, href: attr(link.tag, "href"), name: "", thumbnail: "", tag: link.tag, html: "" }
            cards.push(card)
        }
        var img = firstTag(link.inner, "img")
        if (!card.thumbnail && img) {
            card.thumbnail = imageUrl(img)
        }
        if (!card.name) {
            card.name = attr(link.tag, "data-mxptext") || attr(link.tag, "title") || attr(img, "alt") || attr(img, "title")
                || cleanText(link.inner)
        }
        // the text right after the link usually holds the counts
        card.html += link.inner + html.substr(link.index + link.tag.length + link.inner.length, 400)
    }
    return cards
}

var _categoryHref = /^(?:https?:\/\/[^\/]+)?(?:\/(?:gay|transgender))?\/(?:categories\/[^\/?#"']+|video\?(?:[^"']*&)?c=\d+)/

// [{ category_id, category_url, category_name, category_videos, category_thumbnail }];
// prefix ("" or "/gay") is put in front of the category's address
function parseCategories(html, prefix) {
    html = html || ""
    prefix = prefix || ""
    var scope = _sliceFrom(html, ["id=\"categoriesListSection\"", "categoriesListSection", "id=\"categoryList"]).html
    var categories = []
    var seen = {}

    function add(id, href, name, thumbnail, countText) {
        var url = id ? baseUrl + prefix + "/video?c=" + id : absoluteUrl(href)
        if (!name || !url || seen[url]) {
            return
        }
        seen[url] = true
        var count = parseCount(countText)
        categories.push({
            category_id: id ? parseInt(id, 10) : -1,
            category_url: url,
            category_name: name,
            category_videos: isNaN(count) ? 0 : count,
            category_thumbnail: thumbnail,
        })
    }

    var blocks = _itemBlocks(scope, function (tag) { return hasClass(tag, "catPic") || hasAttr(tag, "data-category") }, 6000)
    for (var i = 0; i < blocks.length; ++i) {
        var block = blocks[i]
        var link = firstTag(block.html, "a", function (tag) { return _isUsableLink(attr(tag, "href")) })
        var img = firstTag(block.html, "img")
        var href = attr(link, "href")
        var id = attr(block.tag, "data-category")
        if (!/^\d+$/.test(id)) {
            var idMatch = /[?&]c=(\d+)/.exec(href)
            id = idMatch ? idMatch[1] : ""
        }
        var name = attr(link, "data-mxptext") || attr(img, "alt") || attr(link, "alt") || attr(link, "title")
        if (!name) {
            var strong = /<strong\b[^>]*>([\s\S]*?)<\/strong>/.exec(block.html)
            name = strong ? cleanText(strong[1]) : cleanText(firstTagInner(block.html, "a"))
        }
        var countMatch = /class\s*=\s*["'][^"']*\bvideoCount\b[^"']*["'][^>]*>([\s\S]*?)<\/span>/.exec(block.html)
            || /<var\b[^>]*>([^<]*)<\/var>/.exec(block.html)
        add(id, href, name, imageUrl(img), countMatch ? cleanText(countMatch[1]) : "")
    }

    if (!categories.length) {
        var cards = _cardsByLink(scope, _categoryHref)
        for (var j = 0; j < cards.length; ++j) {
            var cardId = (/[?&]c=(\d+)/.exec(cards[j].href) || [])[1] || ""
            var videoCount = /([\d][\d,.]*\s*[KkMm]?)\s*(?:videos)?\s*\)?\s*</i.exec(cards[j].html)
            add(cardId, cards[j].href, cards[j].name, cards[j].thumbnail, videoCount ? videoCount[1] : "")
        }
    }
    return categories
}

function firstTagInner(html, tagName) {
    var found = elements(html, tagName)
    return found.length ? found[0].inner : ""
}

var _performerHref = /^(?:https?:\/\/[^\/]+)?\/(pornstar|model|channels)\/([^\/?#"']+)\/?$/

// [{ pornstar_id, pornstar_url, pornstar_name, pornstar_videos, pornstar_views,
//    pornstar_thumbnail, pornstar_rank }] for the performer list and performer search pages
function parsePornstars(html) {
    html = html || ""
    var scope = _sliceFrom(html, ["id=\"popularPornstars\"", "id=\"pornstarsSearchResult\"", "id=\"pornstarListSection\"", "id=\"popularPornstarsSection\""]).html
    var result = []
    var seen = {}

    function add(href, name, thumbnail, rank, videosText, viewsText) {
        var m = _performerHref.exec(href)
        if (!m || !name) {
            return
        }
        var url = baseUrl + "/" + m[1] + "/" + m[2]
        if (seen[url]) {
            return
        }
        seen[url] = true
        var videos = parseCount(videosText)
        result.push({
            pornstar_id: m[2],
            pornstar_kind: m[1],
            pornstar_url: url,
            pornstar_name: name,
            pornstar_videos: isNaN(videos) ? 0 : videos,
            pornstar_views: viewsText,
            pornstar_thumbnail: thumbnail,
            pornstar_rank: rank,
        })
    }

    function details(blockHtml) {
        var rank = parseInt(_textOfClass(blockHtml, "rank_number"), 10)
        var videosMatch = /([\d][\d,.]*)\s*Videos/i.exec(cleanText(blockHtml))
        var viewsMatch = /([\d][\d,.]*\s*[KkMmBb]?)\s*Views/i.exec(cleanText(blockHtml))
        return {
            rank: isNaN(rank) ? 0 : rank,
            videos: videosMatch ? videosMatch[1] : "",
            views: viewsMatch ? viewsMatch[1].replace(/\s+/g, "") : "",
        }
    }

    var blocks = _itemBlocks(scope, function (tag) {
        return hasClass(tag, "performerCard") || hasClass(tag, "pornstarLi") || hasAttr(tag, "data-pornstar-id")
    }, 6000)
    if (!blocks.length) {
        // search results: plain <li> items with a <div class="wrap"> inside
        blocks = _itemBlocks(scope, function () { return true }, 6000).filter(function (block) {
            return /<div\b[^>]*class\s*=\s*["'][^"']*\bwrap\b/.test(block.html.substr(0, 600))
        })
    }
    for (var i = 0; i < blocks.length; ++i) {
        var block = blocks[i]
        var link = firstTag(block.html, "a", function (tag) { return _performerHref.test(attr(tag, "href")) })
        if (!link) {
            continue
        }
        var img = firstTag(block.html, "img")
        var name = _textOfClass(block.html, "performerCardName") || _textOfClass(block.html, "pornStarName")
            || attr(link, "data-mxptext") || attr(img, "alt") || attr(img, "title") || _textOfClass(block.html, "title")
        var d = details(block.html)
        add(attr(link, "href"), name, imageUrl(img), d.rank, d.videos, d.views)
    }

    if (!result.length) {
        var cards = _cardsByLink(scope, _performerHref)
        for (var j = 0; j < cards.length; ++j) {
            var cd = details(cards[j].html)
            add(cards[j].href, cards[j].name, cards[j].thumbnail, cd.rank, cd.videos, cd.views)
        }
    }
    return result
}

// address of the list of videos of a performer, channel or user page
function videosUrlOf(profileUrl) {
    var url = (profileUrl || "").replace(/\/+$/, "")
    if (/\/(pornstar|model|channels|users)\/[^\/?#]+$/.test(url)) {
        return url + "/videos"
    }
    return url
}

// ------------------------------------------------------------------------------------------
// video page

// the JSON text of the object literal that starts at the first "{" at or after start
function _objectLiteralAt(text, start) {
    var open = text.charAt(start)
    var close = open === "[" ? "]" : "}"
    var depth = 0
    var quote = ""
    var escaped = false
    var limit = Math.min(text.length, start + 500000)
    for (var i = start; i < limit; ++i) {
        var c = text.charAt(i)
        if (quote) {
            if (escaped) {
                escaped = false
            } else if (c === "\\") {
                escaped = true
            } else if (c === quote) {
                quote = ""
            }
            continue
        }
        if (c === "\"" || c === "'") {
            quote = c
        } else if (c === open) {
            ++depth
        } else if (c === close) {
            if (--depth === 0) {
                return text.substring(start, i + 1)
            }
        }
    }
    return ""
}

// the object a script assigns to the variable matched by assignment (which ends at "{")
function _jsonAssignment(html, assignment) {
    var m = assignment.exec(html)
    if (!m) {
        return null
    }
    var literal = _objectLiteralAt(html, m.index + m[0].length - 1)
    try {
        return literal ? JSON.parse(literal) : null
    } catch (e) {
        return null
    }
}

function _quality(value) {
    if (typeof value === "number") {
        return Math.floor(value)
    }
    if (typeof value === "string" && /^\s*\d+/.test(value)) {
        return parseInt(value, 10)
    }
    return -1 // several qualities in one adaptive stream
}

// the media definitions in a video page: the flashvars object, or just its list, or the
// single objects in it if the script around them isn't valid JSON
function _mediaDefinitions(html) {
    var flashvars = _jsonAssignment(html, /var\s+flashvars_?\w*\s*=\s*\{/)
    if (flashvars && flashvars.mediaDefinitions instanceof Array) {
        return { flashvars: flashvars, definitions: flashvars.mediaDefinitions }
    }
    var list = /["']?mediaDefinitions["']?\s*:\s*\[/.exec(html)
    if (list) {
        try {
            var parsed = JSON.parse(_objectLiteralAt(html, list.index + list[0].length - 1))
            if (parsed instanceof Array) {
                return { flashvars: flashvars, definitions: parsed }
            }
        } catch (e) {
        }
    }
    var definitions = []
    var re = /\{[^{}]*"videoUrl"\s*:\s*"[^"]*"[^{}]*\}/g
    var m
    while ((m = re.exec(html)) !== null) {
        try {
            definitions.push(JSON.parse(m[0]))
        } catch (e) {
        }
    }
    return { flashvars: flashvars, definitions: definitions }
}

// the media_N, quality_N, qualityItems_N variables older pages built the addresses from
function _obfuscatedMediaUrls(html) {
    var urls = []
    var index = html.search(/var\s+(?:media|quality|qualityItems)_/)
    if (index < 0) {
        return urls
    }
    // the whole line: the parts are assigned to variables before the media ones
    var lineEnd = html.indexOf("\n", index)
    var line = html.substring(html.lastIndexOf("\n", index) + 1, lineEnd >= 0 ? lineEnd : html.length)
    var vars = {}
    var statements = line.split(";")
    for (var i = 0; i < statements.length; ++i) {
        var statement = statements[i].replace(/\/\*[\s\S]*?\*\//g, "").replace(/^\s*var\s+/, "")
        var eq = statement.indexOf("=")
        if (eq < 0) {
            continue
        }
        var name = statement.substring(0, eq).trim()
        if (!/^[A-Za-z_$][\w$]*$/.test(name)) {
            continue
        }
        var parts = statement.substring(eq + 1).split("+")
        var value = ""
        for (var j = 0; j < parts.length; ++j) {
            var part = parts[j].trim()
            value += vars.hasOwnProperty(part) ? vars[part] : part.replace(/^["']|["']$/g, "")
        }
        vars[name] = value
        if (/^(media|quality)_/.test(name) && /^https?:\/\//.test(value)) {
            urls.push(value)
        }
    }
    return urls
}

// [{ format, quality, url }] from a media definition list (the flashvars one or the one
// get_media answers with); addresses of further lists to fetch are returned in getMediaUrls
function mediaFromDefinitions(definitions) {
    var formats = []
    var getMediaUrls = []
    var seen = {}
    for (var i = 0; i < (definitions || []).length; ++i) {
        var definition = definitions[i]
        if (!definition || typeof definition !== "object") {
            continue
        }
        var url = typeof definition.videoUrl === "string" ? absoluteUrl(decodeEntities(definition.videoUrl)) : ""
        if (!url || seen[url]) {
            continue
        }
        seen[url] = true
        if (url.indexOf("/video/get_media") >= 0) {
            getMediaUrls.push(url)
            continue
        }
        var format = String(definition.format || "").toLowerCase()
        if (!format) {
            format = /\.m3u8(\?|$)/.test(url) ? "hls" : "mp4"
        }
        formats.push({ format: format, quality: _quality(definition.quality), url: url })
    }
    return { formats: formats, getMediaUrls: getMediaUrls }
}

// [{ format, quality, url }] from the answer to a get_media request
function parseMediaList(text) {
    var list
    try {
        list = JSON.parse(text)
    } catch (e) {
        return []
    }
    if (list && !(list instanceof Array) && list.mediaDefinitions instanceof Array) {
        list = list.mediaDefinitions
    }
    return list instanceof Array ? mediaFromDefinitions(list).formats : []
}

// links of elements marked data-label="label" (category, tag, pornstar)
function _labelledLinks(html, label) {
    var result = []
    var seen = {}
    var found = elements(html, "[a-zA-Z][a-zA-Z0-9]*", function (tag) { return attr(tag, "data-label") === label })
    for (var i = 0; i < found.length; ++i) {
        var tag = found[i].tag
        var href = /^<a\b/i.test(tag) ? attr(tag, "href") : attr(firstTag(found[i].inner, "a"), "href")
        var name = cleanText(found[i].inner)
        if (name && !seen[name]) {
            seen[name] = true
            result.push({ name: name, href: href })
        }
    }
    return result
}

// links inside the first element whose class list contains wrapperClass (older pages)
function _wrappedLinks(html, wrapperClass) {
    var wrappers = elements(html, "div", function (tag) { return hasClass(tag, wrapperClass) })
    var result = []
    if (wrappers.length) {
        var links = elements(wrappers[0].inner, "a")
        for (var i = 0; i < links.length; ++i) {
            var name = attr(links[i].tag, "data-mxptext") || cleanText(links[i].inner)
            var href = attr(links[i].tag, "href")
            if (name && _isUsableLink(href) && !/^\+/.test(name)) {
                result.push({ name: name, href: href })
            }
        }
    }
    return result
}

function _contextNames(html, kind) {
    var meta = firstTag(html, "meta", function (tag) { return attr(tag, "name") === "adsbytrafficjunkycontext" })
    var value = attr(meta, "data-context-" + kind)
    return value ? value.split(",").map(function (s) { return s.trim() }).filter(function (s) { return !!s }) : []
}

function _slug(name) {
    return name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "")
}

// "/model/name" from "https://www.pornhub.com/model/name/"
function _sitePath(href) {
    return String(href || "").replace(/^(?:https?:)?\/\/[^\/]+/, "").replace(/\/+$/, "")
}

function _uploader(html) {
    var regions = ["userInfoBlock", "video-info-row", "usernameWrap"]
    for (var i = 0; i < regions.length; ++i) {
        var index = html.search(new RegExp("class\\s*=\\s*[\"'][^\"']*\\b" + regions[i] + "\\b"))
        if (index < 0) {
            continue
        }
        var region = html.substr(index, 4000)
        var links = elements(region, "a", function (tag) { return /^\/(model|pornstar|channels|users)\/[^\/?#]+/.test(attr(tag, "href")) })
        for (var j = 0; j < links.length; ++j) {
            var name = cleanText(links[j].inner)
            if (name) {
                return { name: name, url: _sitePath(attr(links[j].tag, "href")) }
            }
        }
    }
    var profile = _jsonAssignment(html, /var\s+MODEL_PROFILE\s*=\s*\{/)
    if (profile && profile.username && profile.modelProfileLink) {
        return { name: String(profile.username), url: _sitePath(String(profile.modelProfileLink)) }
    }
    return { name: "", url: "" }
}

function _votes(html, className) {
    var tag = firstTag(html, "span", function (t) { return hasClass(t, className) })
    if (!tag) {
        return -1
    }
    var rating = parseInt(attr(tag, "data-rating"), 10)
    if (!isNaN(rating)) {
        return rating
    }
    var text = html.substr(html.indexOf(tag) + tag.length, 200)
    var count = parseCount(text.substring(0, text.indexOf("<") >= 0 ? text.indexOf("<") : text.length))
    return isNaN(count) ? -1 : count
}

// everything the player page needs from a video page:
// { title, formats: [{ format, quality, url }], getMediaUrls, upVotes, downVotes, isFavorite,
//   ratingToken, model: { name, url }, categories: [{ category_title, category_url }],
//   pornstars: [{ pornstar_name, pornstar_url }], tags: [{ tag_name, tag_url }],
//   unavailableMessage, problem }
function parseVideoPage(html) {
    html = html || ""
    var media = _mediaDefinitions(html)
    var found = mediaFromDefinitions(media.definitions)
    if (!found.formats.length && !found.getMediaUrls.length) {
        var old = _obfuscatedMediaUrls(html)
        var definitions = []
        for (var i = 0; i < old.length; ++i) {
            definitions.push({ videoUrl: old[i], quality: (/(\d{3,4})[pP]_\d+[kK]/.exec(old[i]) || [])[1] || "" })
        }
        found = mediaFromDefinitions(definitions)
    }

    var result = {
        title: "",
        formats: found.formats,
        getMediaUrls: found.getMediaUrls,
        upVotes: -1,
        downVotes: -1,
        isFavorite: false,
        ratingToken: "",
        model: _uploader(html),
        categories: [],
        pornstars: [],
        tags: [],
        unavailableMessage: "",
        problem: pageProblem(html),
    }

    var titleMeta = firstTag(html, "meta", function (tag) { return attr(tag, "property") === "og:title" || attr(tag, "name") === "twitter:title" })
    result.title = attr(titleMeta, "content") || (media.flashvars && media.flashvars.video_title ? String(media.flashvars.video_title) : "")

    var ratings = _jsonAssignment(html, /WIDGET_RATINGS_LIKE_FAV\s*=\s*\{/)
    if (ratings) {
        result.upVotes = typeof ratings.currentUp === "number" ? ratings.currentUp : parseInt(ratings.currentUp, 10)
        result.downVotes = typeof ratings.currentDown === "number" ? ratings.currentDown : parseInt(ratings.currentDown, 10)
        result.isFavorite = ratings.isFavourite === 1 || ratings.isFavourite === "1" || ratings.isFavourite === true
        if (ratings.token) {
            result.ratingToken = String(ratings.token)
        }
    }
    var token = /WIDGET_RATINGS_LIKE_FAV\.token\s*=\s*["']([^"']+)["']/.exec(html)
    if (token) {
        result.ratingToken = token[1]
    }
    if (isNaN(result.upVotes) || result.upVotes < 0) {
        result.upVotes = _votes(html, "votesUp")
    }
    if (isNaN(result.downVotes) || result.downVotes < 0) {
        result.downVotes = _votes(html, "votesDown")
    }

    var categories = _labelledLinks(html, "category")
    if (!categories.length) {
        categories = _wrappedLinks(html, "categoriesWrapper")
    }
    for (var c = 0; c < categories.length; ++c) {
        var id = (/[?&]c=(\d+)/.exec(categories[c].href) || [])[1]
        result.categories.push({
            category_id: id ? parseInt(id, 10) : -1,
            category_title: categories[c].name,
            category_url: _isUsableLink(categories[c].href) ? absoluteUrl(categories[c].href) : baseUrl + "/categories/" + _slug(categories[c].name),
        })
    }
    var pornstars = _labelledLinks(html, "pornstar")
    if (!pornstars.length) {
        pornstars = _wrappedLinks(html, "pornstarsWrapper")
    }
    for (var p = 0; p < pornstars.length; ++p) {
        result.pornstars.push({
            pornstar_name: pornstars[p].name,
            pornstar_url: _isUsableLink(pornstars[p].href) ? absoluteUrl(pornstars[p].href) : baseUrl + "/pornstar/" + _slug(pornstars[p].name),
        })
    }
    var tags = _labelledLinks(html, "tag")
    if (!tags.length) {
        tags = _wrappedLinks(html, "tagsWrapper")
    }
    for (var t = 0; t < tags.length; ++t) {
        result.tags.push({
            tag_name: tags[t].name,
            tag_url: _isUsableLink(tags[t].href) ? absoluteUrl(tags[t].href) : baseUrl + "/video/search?search=" + encodeURIComponent(tags[t].name),
        })
    }

    // the page's ad context lists the names when the links aren't found
    var kinds = [["category", "categories"], ["pornstar", "pornstars"], ["tag", "tags"]]
    for (var k = 0; k < kinds.length; ++k) {
        if (result[kinds[k][1]].length) {
            continue
        }
        var names = _contextNames(html, kinds[k][0])
        for (var n = 0; n < names.length; ++n) {
            if (kinds[k][0] === "category") {
                result.categories.push({ category_id: -1, category_title: names[n], category_url: baseUrl + "/categories/" + _slug(names[n]) })
            } else if (kinds[k][0] === "pornstar") {
                result.pornstars.push({ pornstar_name: names[n], pornstar_url: baseUrl + "/pornstar/" + _slug(names[n]) })
            } else {
                result.tags.push({ tag_name: names[n], tag_url: baseUrl + "/video/search?search=" + encodeURIComponent(names[n]) })
            }
        }
    }

    if (!result.formats.length && !result.getMediaUrls.length) {
        result.unavailableMessage = videoUnavailableMessage(html)
    }
    return result
}

// ------------------------------------------------------------------------------------------
// diagnostics

// the structure of a piece of markup without its content: tags, attribute names, class and id
// values and the path of links are kept; text, titles and other values are replaced by "…"
function skeleton(html, maxLength) {
    var keep = { "class": true, "id": true, "type": true, "name": true, "rel": true, "data-label": true, "data-segment": true }
    var result = String(html || "")
        .replace(/<!--[\s\S]*?-->/g, "")
        .replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, "<script>…</script>")
        .replace(/<style\b[^>]*>[\s\S]*?<\/style>/gi, "")
        .replace(/(<\/?[a-zA-Z][^>]*>)|([^<]+)/g, function (m, tag, text) {
            if (text !== undefined && text !== "" && !tag) {
                return /\S/.test(text) ? "…" : " "
            }
            return tag.replace(/(\s[\w:.-]+)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'>]+))/g, function (a, name, v1, v2, v3) {
                var value = v1 || v2 || v3 || ""
                var key = name.trim().toLowerCase()
                if (keep[key]) {
                    return name + "=\"" + value + "\""
                }
                if (key === "href" || key === "action") {
                    var path = value.replace(/^https?:\/\/[^\/]+/, "")
                    var query = path.indexOf("?")
                    var shortPath = query >= 0 ? path.substring(0, query) : path
                    // first path segment only: the rest names people or videos
                    shortPath = shortPath.replace(/^(\/[^\/]*\/)[\s\S]+$/, "$1…")
                    var params = query >= 0 ? path.substring(query + 1).split("&").map(function (p) { return p.split("=")[0] + "=…" }).join("&") : ""
                    return name + "=\"" + shortPath + (params ? "?" + params : "") + "\""
                }
                if (/^(?:https?:)?\/\//.test(value)) {
                    return name + "=\"url\""
                }
                if (value.indexOf("data:") === 0) {
                    return name + "=\"data:\""
                }
                return name + "=\"…\""
            })
        })
        .replace(/\s+/g, " ")
    return maxLength && result.length > maxLength ? result.substring(0, maxLength) + " [cut]" : result
}

// the markup around the first match of pattern, as a skeleton; "" if there is no match
function skeletonAround(html, pattern, before, length) {
    var index = (html || "").search(pattern)
    if (index < 0) {
        return ""
    }
    var start = Math.max(0, html.lastIndexOf("<", Math.max(0, index - (before || 0))))
    return skeleton(html.substr(start, length || 3000), 2000)
}
