// The Node half of compare-engines.sh: same output as qml/ScraperDump.qml.
"use strict"
const fs = require("fs"), path = require("path"), vm = require("vm")
const S = {}
vm.createContext(S)
vm.runInContext(fs.readFileSync(path.join(__dirname, "..", "qml", "Scraper.js"), "utf8").replace(/^\.pragma library\s*$/m, ""), S)
const read = name => fs.readFileSync(path.join(__dirname, "fixtures", name), "utf8")
const pages = ["video-list.html", "video-list-2020.html", "categories.html", "categories-cards.html",
    "pornstars.html", "pornstars-search.html", "video-page.html", "video-page-context-only.html",
    "video-page-obfuscated.html", "video-removed.html", "login-page.html", "home-modal.html",
    "geo-blocked.html", "challenge.html"]
for (const name of pages) {
    const html = read(name)
    const result = {
        list: S.parseVideoList(html),
        categories: S.parseCategories(html, "/gay"),
        pornstars: S.parsePornstars(html),
        page: S.parseVideoPage(html),
        session: [S.isLoggedIn(html), S.logoutToken(html), S.username(html), S.loginFields(html)],
        problem: S.pageProblem(html),
        skeleton: S.skeleton(html.substring(0, 1500)),
    }
    console.log("RESULT " + name + " " + JSON.stringify(result))
}
console.log("RESULT get-media.json " + JSON.stringify(S.parseMediaList(read("get-media.json"))))
console.log("RESULT form " + S.loginBody({ token: "T" }, "me+1@example.com", "p&ss=w%rd"))
