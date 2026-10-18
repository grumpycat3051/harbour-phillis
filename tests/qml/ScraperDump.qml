// Runs qml/Scraper.js in Qt's own JavaScript engine over the fixtures and prints the results,
// so tests/compare-engines.sh can check they match what Node computes.
import QtQuick 2.0
import "../../qml/Scraper.js" as Scraper

Item {
    function read(name) {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", Qt.resolvedUrl("../fixtures/" + name), false)
        xhr.send()
        return xhr.responseText
    }

    Component.onCompleted: {
        var pages = ["video-list.html", "video-list-2020.html", "categories.html", "categories-cards.html",
                     "pornstars.html", "pornstars-search.html", "video-page.html", "video-page-context-only.html",
                     "video-page-obfuscated.html", "video-removed.html", "login-page.html", "home-modal.html",
                     "geo-blocked.html", "challenge.html"]
        for (var i = 0; i < pages.length; ++i) {
            var html = read(pages[i])
            var result = {
                list: Scraper.parseVideoList(html),
                categories: Scraper.parseCategories(html, "/gay"),
                pornstars: Scraper.parsePornstars(html),
                page: Scraper.parseVideoPage(html),
                session: [Scraper.isLoggedIn(html), Scraper.logoutToken(html), Scraper.username(html), Scraper.loginFields(html)],
                problem: Scraper.pageProblem(html),
                skeleton: Scraper.skeleton(html.substring(0, 1500)),
            }
            console.log("RESULT " + pages[i] + " " + JSON.stringify(result))
        }
        console.log("RESULT get-media.json " + JSON.stringify(Scraper.parseMediaList(read("get-media.json"))))
        console.log("RESULT form " + Scraper.loginBody({ token: "T" }, "me+1@example.com", "p&ss=w%rd"))
        Qt.quit()
    }
}
