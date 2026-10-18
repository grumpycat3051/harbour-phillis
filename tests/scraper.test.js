// Tests for qml/Scraper.js. Run with:  node tests/scraper.test.js
// The fixtures are hand-made pages in the shape of the site's markup (old and current).
"use strict"

const assert = require("assert")
const fs = require("fs")
const path = require("path")
const vm = require("vm")

const root = path.join(__dirname, "..")
const source = fs.readFileSync(path.join(root, "qml", "Scraper.js"), "utf8").replace(/^\.pragma library\s*$/m, "")
const S = {}
vm.createContext(S)
vm.runInContext(source, S, { filename: "Scraper.js" })

const fixture = name => fs.readFileSync(path.join(__dirname, "fixtures", name), "utf8")
// objects made in the script's context have another Object prototype: compare plain copies
const plain = value => JSON.parse(JSON.stringify(value))

let failures = 0
function test(name, fn) {
    try {
        fn()
        console.log("ok   " + name)
    } catch (e) {
        failures++
        console.log("FAIL " + name + "\n     " + (e && e.stack || e).toString().split("\n").slice(0, 6).join("\n     "))
    }
}

test("helpers", () => {
    assert.strictEqual(S.decodeEntities("a &amp; b &lt;c&gt; &#39;d&#x27; &quot;e&quot; &nbsp;&hellip;"), "a & b <c> 'd' \"e\"  &hellip;")
    assert.strictEqual(S.attr('<a href="/x" title=\'T &amp; U\' data-id=5>', "title"), "T & U")
    assert.strictEqual(S.attr('<a href="/x" data-id=5>', "data-id"), "5")
    assert.strictEqual(S.attr('<img data-src="a" src="b">', "src"), "b")
    assert.strictEqual(S.attr('<a data-title="x">', "title"), "")
    assert.strictEqual(S.parseCount("2.8K"), 2800)
    assert.strictEqual(S.parseCount("(74,930)"), 74930)
    assert.strictEqual(S.parseCount("554M Views"), 554000000)
    assert.ok(isNaN(S.parseCount("none")))
    assert.strictEqual(S.absoluteUrl("//ei.phncdn.com/a.jpg"), "https://ei.phncdn.com/a.jpg")
    assert.strictEqual(S.absoluteUrl("/video?c=1"), "https://www.pornhub.com/video?c=1")
    assert.strictEqual(S.videosUrlOf("https://www.pornhub.com/pornstar/x"), "https://www.pornhub.com/pornstar/x/videos")
    assert.strictEqual(S.videosUrlOf("https://www.pornhub.com/video?c=1"), "https://www.pornhub.com/video?c=1")
    const nested = S.elements("<div class=a><div>x</div>y</div><div class=b>z</div>", "div", t => S.hasClass(t, "a"))
    assert.strictEqual(nested.length, 1)
    assert.strictEqual(nested[0].inner, "<div>x</div>y")
})

test("current video list", () => {
    const list = plain(S.parseVideoList(fixture("video-list.html")))
    assert.strictEqual(list.container, 'id="videoCategory"')
    assert.deepStrictEqual(list.videos.map(v => v.video_viewkey), ["6612abcd01", "ph5f9280abe0e56"])
    const first = list.videos[0]
    assert.strictEqual(first.video_url, "https://www.pornhub.com/view_video.php?viewkey=6612abcd01")
    assert.strictEqual(first.video_id, "1001")
    assert.strictEqual(first.video_title, "Sample video one & more")
    assert.strictEqual(first.video_thumbnail, "https://ei.phncdn.com/videos/202601/01/1001/original/(m=eafTGgaaaa)(mh=abc)1.jpg")
    assert.strictEqual(first.video_length, "12:34")
    assert.strictEqual(first.video_views, "2.8K")
    assert.strictEqual(first.video_rating, 82)
    assert.strictEqual(first.video_added, "22 hours ago")
    const second = list.videos[1]
    assert.strictEqual(second.video_title, "Second sample")
    assert.strictEqual(second.video_thumbnail, "https://ei.phncdn.com/videos/202601/01/1002/thumb.jpg")
    assert.strictEqual(second.video_length, "1:05:00")
    assert.strictEqual(second.video_views, "1,234")
    assert.strictEqual(second.video_rating, -1)
    assert.strictEqual(list.hasNextPage, true)
    assert.strictEqual(list.nextUrl, "https://www.pornhub.com/video?o=ht&page=2")
})

test("2020 video list markup", () => {
    const list = plain(S.parseVideoList(fixture("video-list-2020.html")))
    assert.strictEqual(list.videos.length, 1)
    const v = list.videos[0]
    assert.strictEqual(v.video_title, "Old style title")
    assert.strictEqual(v.video_id, "363214972")
    assert.ok(v.video_thumbnail.indexOf("https://ci.phncdn.com/videos/202010/23/363214972/") === 0)
    assert.strictEqual(v.video_length, "1:00")
    assert.strictEqual(v.video_views, "2.8K")
    assert.strictEqual(v.video_rating, 82)
    assert.strictEqual(list.hasNextPage, false, "disabled next button")
})

test("categories", () => {
    const categories = plain(S.parseCategories(fixture("categories.html"), "/gay"))
    assert.strictEqual(categories.length, 2)
    assert.deepStrictEqual(categories[0], {
        category_id: 27,
        category_url: "https://www.pornhub.com/gay/video?c=27",
        category_name: "First Category",
        category_videos: 74930,
        category_thumbnail: "https://ci.phncdn.com/is-static/images/categories/(m=q41656TbetZD8zjadOf)(mh=4dqQygrsXSKDpore)roku_27.jpg",
    })
    assert.strictEqual(categories[1].category_id, 111)
    assert.strictEqual(categories[1].category_name, "Second Category & Co")
    assert.strictEqual(categories[1].category_videos, 12300)
    assert.strictEqual(categories[1].category_thumbnail, "https://ei.phncdn.com/is-static/images/categories/roku_111.jpg")
})

test("categories without list items", () => {
    const categories = plain(S.parseCategories(fixture("categories-cards.html"), ""))
    assert.deepStrictEqual(categories.map(c => [c.category_name, c.category_url, c.category_videos, c.category_thumbnail]), [
        ["First Card", "https://www.pornhub.com/categories/first-card", 1234, "https://ei.phncdn.com/c1.jpg"],
        ["Second Card", "https://www.pornhub.com/video?c=5", 99, "https://ei.phncdn.com/c2.jpg"],
    ])
})

test("performer list", () => {
    const list = plain(S.parsePornstars(fixture("pornstars.html")))
    assert.strictEqual(list.length, 2)
    assert.deepStrictEqual(list[0], {
        pornstar_id: "first-performer",
        pornstar_kind: "pornstar",
        pornstar_url: "https://www.pornhub.com/pornstar/first-performer",
        pornstar_name: "First Performer",
        pornstar_videos: 1873,
        pornstar_views: "554M",
        pornstar_thumbnail: "https://ei.phncdn.com/pics/pornstars/000/001/(m=lciuhScOb_c)thumb_1.jpg",
        pornstar_rank: 1,
    })
    assert.strictEqual(list[1].pornstar_url, "https://www.pornhub.com/model/second-model")
    assert.strictEqual(list[1].pornstar_name, "Second Model")
    assert.strictEqual(list[1].pornstar_views, "1.5K")
    assert.strictEqual(S.nextPage(fixture("pornstars.html")).hasNextPage, true)
})

test("performer search", () => {
    const list = plain(S.parsePornstars(fixture("pornstars-search.html")))
    assert.strictEqual(list.length, 1)
    assert.strictEqual(list[0].pornstar_name, "Searched Performer")
    assert.strictEqual(list[0].pornstar_rank, 28)
    assert.strictEqual(list[0].pornstar_videos, 1873)
    assert.strictEqual(list[0].pornstar_views, "554M")
    assert.ok(list[0].pornstar_thumbnail.indexOf("https://ci.phncdn.com/pics/users/375/") === 0)
    assert.strictEqual(S.nextPage(fixture("pornstars-search.html")).hasNextPage, false)
})

test("video page", () => {
    const page = plain(S.parseVideoPage(fixture("video-page.html")))
    assert.strictEqual(page.title, "Sample video one & more")
    assert.deepStrictEqual(page.formats, [
        { format: "hls", quality: 720, url: "https://ev-h.phncdn.com/hls/videos/202601/01/1001/720P_4000K_1001.mp4/master.m3u8?validfrom=1&validto=2&hash=abc%3D" },
        { format: "hls", quality: 480, url: "https://ev-h.phncdn.com/hls/videos/202601/01/1001/480P_2000K_1001.mp4/master.m3u8?validfrom=1&validto=2&hash=def" },
    ])
    assert.deepStrictEqual(page.getMediaUrls, ["https://www.pornhub.com/video/get_media?s=eyJrIjoiYWJjIn0&v=6612abcd01&e=0&t=p"])
    assert.strictEqual(page.upVotes, 1234)
    assert.strictEqual(page.downVotes, 56)
    assert.strictEqual(page.isFavorite, true)
    assert.strictEqual(page.ratingToken, "RATINGTOKEN1")
    assert.deepStrictEqual(page.model, { name: "Some Model", url: "/model/some-model" })
    assert.deepStrictEqual(page.categories, [
        { category_id: -1, category_title: "Amateur", category_url: "https://www.pornhub.com/categories/amateur" },
        { category_id: 8, category_title: "Big Category", category_url: "https://www.pornhub.com/video?c=8" },
    ])
    assert.deepStrictEqual(page.pornstars, [{ pornstar_name: "First Performer", pornstar_url: "https://www.pornhub.com/pornstar/first-performer" }])
    assert.deepStrictEqual(page.tags.map(t => t.tag_name), ["tag one", "tag two"])
    assert.strictEqual(page.tags[0].tag_url, "https://www.pornhub.com/video/search?search=tag+one")
    assert.strictEqual(page.unavailableMessage, "")
    assert.strictEqual(page.problem, "")
})

test("video page with only the ad context and a relative get_media address", () => {
    const page = plain(S.parseVideoPage(fixture("video-page-context-only.html")))
    assert.deepStrictEqual(page.formats, [])
    assert.deepStrictEqual(page.getMediaUrls, ["https://www.pornhub.com/video/get_media?s=abc&v=x77"])
    assert.strictEqual(page.upVotes, 2500)
    assert.strictEqual(page.downVotes, 100)
    assert.deepStrictEqual(page.model, { name: "Profile Name", url: "/model/profile-name" })
    assert.deepStrictEqual(page.tags.map(t => t.tag_url), [
        "https://www.pornhub.com/video/search?search=ctx%20tag",
        "https://www.pornhub.com/video/search?search=second%20tag",
    ])
    assert.deepStrictEqual(page.categories, [{ category_id: -1, category_title: "Ctx Category", category_url: "https://www.pornhub.com/categories/ctx-category" }])
    assert.deepStrictEqual(page.pornstars, [{ pornstar_name: "Ctx Performer", pornstar_url: "https://www.pornhub.com/pornstar/ctx-performer" }])
})

test("older pages that build the addresses in variables", () => {
    const page = plain(S.parseVideoPage(fixture("video-page-obfuscated.html")))
    assert.deepStrictEqual(page.formats, [
        { format: "mp4", quality: 720, url: "https://ev.phncdn.com/videos/202001/01/55/720P_1500K_55.mp4?x=1" },
        { format: "mp4", quality: 480, url: "https://ev.phncdn.com/videos/202001/01/55/480P_600K_55.mp4?x=2" },
    ])
})

test("removed video", () => {
    const page = plain(S.parseVideoPage(fixture("video-removed.html")))
    assert.strictEqual(page.unavailableMessage, "This video has been removed at the request of the uploader.")
})

test("get_media answer", () => {
    const formats = plain(S.parseMediaList(fixture("get-media.json")))
    assert.deepStrictEqual(formats.map(f => [f.format, f.quality]), [["mp4", 720], ["mp4", 1080], ["mp4", 240]])
    assert.strictEqual(formats[0].url, "https://ev.phncdn.com/videos/202601/01/1001/720P_4000K_1001.mp4?validfrom=1&validto=2&hash=xyz")
    assert.deepStrictEqual(plain(S.parseMediaList("not json")), [])
    assert.deepStrictEqual(plain(S.parseMediaList('{"mediaDefinitions":[{"videoUrl":"https://a/b.mp4","quality":"480"}]}')), [{ format: "mp4", quality: 480, url: "https://a/b.mp4" }])
})

test("session", () => {
    const html = fixture("video-page.html")
    assert.strictEqual(S.isLoggedIn(html), true)
    assert.strictEqual(S.logoutToken(html), "LOGOUTTOKEN1")
    assert.strictEqual(S.username(html), "my-name")
    assert.strictEqual(S.isLoggedIn(fixture("video-list.html")), false)
    assert.deepStrictEqual(plain(S.loginFields(fixture("login-page.html"))), {
        redirect: "L2Zyb250", token: "LOGINTOKEN1", from: "pc_login_modal_:show", intended_action: "",
    })
    assert.deepStrictEqual(plain(S.loginFields(fixture("home-modal.html"))), { token: "MODALTOKEN", redirect: "" })
    assert.deepStrictEqual(plain(S.loginFields("<html></html>")), {})
    assert.strictEqual(S.formEncode({ a: "x y", "b c": "p+w%41&=é" }), "a=x+y&b+c=p%2Bw%2541%26%3D%C3%A9")
    const body = new URLSearchParams(S.loginBody({ token: "T", redirect: "" }, "me@example.com", "pa+ss word"))
    assert.deepStrictEqual(Object.fromEntries(body), {
        token: "T", redirect: "", username: "me@example.com", email: "me@example.com",
        password: "pa+ss word", remember_me: "1", from: "pc_login_modal_:show",
    })
    assert.deepStrictEqual(plain(S.parseLoginResponse('{"success":"1","message":""}')), { success: true, message: "" })
    assert.deepStrictEqual(plain(S.parseLoginResponse('{"success":"0","message":"Invalid username\\/password"}')), { success: false, message: "Invalid username/password" })
    assert.deepStrictEqual(plain(S.parseLoginResponse("<html>")), { success: false, message: "" })
})

test("blocked pages", () => {
    assert.strictEqual(S.pageProblem(fixture("geo-blocked.html")), "geo")
    assert.strictEqual(S.pageProblem(fixture("challenge.html")), "challenge")
    assert.strictEqual(S.pageProblem(fixture("video-list.html")), "")
    assert.strictEqual(S.pageTitle(fixture("video-list.html")), "Hottest Videos | Pornhub")
})

test("skeleton hides content", () => {
    const sk = S.skeleton('<li class="videoblock" data-video-vkey="abc"><a href="/view_video.php?viewkey=abc" title="Secret title"><img src="https://x/y.jpg" alt="Secret"></a><span class="views">12 views</span></li>')
    assert.ok(sk.indexOf("Secret") < 0, sk)
    assert.ok(sk.indexOf('class="videoblock"') >= 0, sk)
    assert.ok(sk.indexOf('href="/view_video.php?viewkey=…"') >= 0, sk)
    assert.ok(sk.indexOf('src="url"') >= 0, sk)
    assert.strictEqual(S.skeleton('<a href="/pornstar/some-name">x</a>'), '<a href="/pornstar/…">…</a>')
    assert.strictEqual(S.skeletonAround("<div><p id=x>t</p></div>", /id=x/, 0, 100), '<p id="x">…</p></div>')
})

test("large page stays fast", () => {
    const item = fixture("video-list.html").match(/<li class="pcVideoListItem[\s\S]*?<\/li>/g)[1]
    const items = Array.from({ length: 200 }, (_, i) => item.replace(/6612abcd01/g, "key" + i)).join("\n")
    const page = "<ul id=\"videoCategory\">" + items + "</ul>" + "<div class=\"x\"><a href=\"/a\">filler</a></div>".repeat(5000)
    const t0 = Date.now()
    assert.strictEqual(S.parseVideoList(page).videos.length, 200)
    S.parseVideoPage(page)
    S.parseCategories(page, "")
    S.parsePornstars(page)
    const ms = Date.now() - t0
    assert.ok(ms < 500, "took " + ms + " ms")
})

console.log(failures ? failures + " test(s) failed" : "all tests passed")
process.exit(failures ? 1 : 0)
