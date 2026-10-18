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
import Nemo.DBus 2.0
import Nemo.Notifications 1.0
import grumpycat 1.0
import "."
import "Scraper.js" as Scraper

ApplicationWindow
{
    id: window
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    initialPage: !disclaimerAccepted.value
                 ? Qt.resolvedUrl("pages/AdultContentDisclaimerPage.qml")
                 : Qt.resolvedUrl("pages/StartPage.qml")
    allowedOrientations: defaultAllowedOrientations

    property bool _pausedDueToDisplayState: false
    property var videoPlayerPage
    property string loginToken
    property string logoutToken
    readonly property string username: _username
    property string _username
    // hidden fields of the site's login form (token, redirect, ...)
    property var _loginFields: ({})
    readonly property bool isUserLoggedIn: _userIsLoggedIn
    property bool _userIsLoggedIn: false
    readonly property bool restrictAccess: settingAccessRestrict.value && settingLockScreenPin.value
    readonly property bool hasLoginData: !!settingAccountUsername.value && !!settingAccountPassword.value
    readonly property bool canAutoLogin: settingAccountLoginOnAppStart.value && hasLoginData
    property bool _autoLoginTried: false

    property int _action: -1
    readonly property int actionInit: 0
    readonly property int actionLogin: 1
    readonly property int actionLogout: 2
    readonly property int actionLoginPage: 3

    property bool debugVideoPlayer: false

    Http {
        id: http
        onStatusChanged: {
            if (status !== Http.StatusCompleted) {
                return
            }
            console.debug("completed error=" + error + " http status=" + httpStatusCode)
            switch (_action) {
            case actionLoginPage:
                // a fresh token for the login form, even if the page itself failed
                updateSessionHtml(data)
                if (isUserLoggedIn) {
                    _action = -1
                } else {
                    _sendLogin()
                }
                break
            case actionLogin:
                _action = -1
                var result = Scraper.parseLoginResponse(data)
                if (Http.ErrorNone === error && result.success) {
                    _userIsLoggedIn = true
                    console.debug("login success")
                    //% "Login success"
                    window.notify(qsTrId("ph-login-succes-message"))

                    // load a page to have logout token for menu
                    // weirdly this doens't work if using the base page
                    _action = actionInit
                    http.get(Constants.baseUrl + "/categories")
                } else {
                    _userIsLoggedIn = false
                    //% "Login failed"
                    window.notify(result.message || window.problemMessage(data) || qsTrId("ph-login-failed-message"))
                }
                break
            case actionLogout:
                _action = -1
                _userIsLoggedIn = false
                logoutToken = ""
                _username = ""
                updateSessionHtml(data)
                break
            case actionInit:
                _action = -1
                if (Http.ErrorNone === error) {
                    updateSessionHtml(data)
                    var problem = window.problemMessage(data)
                    if (problem) {
                        window.notify(problem)
                    } else if (!isUserLoggedIn && canAutoLogin && !_autoLoginTried) {
                        _autoLoginTried = true
                        login()
                    }
                } else {
                    //% "Initial loading of website failed"
                    var str = window.problemMessage(data) || qsTrId("ph-error-message-initial-request-failed")
                    downloadError(url, error, str)
                }
                break
            default:
                if (Http.ErrorNone !== error) {
                    downloadError(url, error, errorMessage)
                }
                break
            }
        }
    }



    ConfigurationValue {
        id: settingBroadbandDefaultFormat
        defaultValue: Constants.formatBest
        key: "/format/broadband"
    }

    ConfigurationValue {
        id: settingMobileDefaultFormat
        defaultValue: Constants.formatWorst
        key: "/format/mobile"
    }

    ConfigurationValue {
        id: settingBearerMode
        defaultValue: Constants.bearerModeAutoDetect
        key: "/bearer/mode"
    }

    ConfigurationValue {
        id: settingGayOnly
        defaultValue: false
        key: "/gay_only"
        onValueChanged: {
            console.debug("gay only=" + value)
        }
    }

    ConfigurationValue {
        id: settingDisplayVideosPerRow
        defaultValue: 1
        key: "/display/videos_per_grid_row"
    }

    ConfigurationValue {
        id: settingDisplayCategoriesPerRow
        defaultValue: 1
        key: "/display/categories_per_grid_row"
    }

    ConfigurationValue {
        id: settingDisplayPornstarsPerRow
        defaultValue: 2
        key: "/display/pornstars_per_grid_row"
    }

    ConfigurationValue {
        id: settingDisplayExtraLandscapeColumn
        key: "/display/extra_landscape_column"
        defaultValue: true
    }

    ConfigurationValue {
        id: settingPlaybackPauseInCoverMode
        key: "/playback/pause_in_cover_mode"
        defaultValue: false
    }

    ConfigurationValue {
        id: settingPlaybackPauseOnDeviceLock
        key: "/playback/pause_on_device_lock"
        defaultValue: true
    }

    ConfigurationValue {
        id: settingPlaybackVideoReloadAttempts
        key: "/playback/video_reload_attempts"
        defaultValue: 3
    }

    ConfigurationValue {
        id: debugApp
        key: "/debug"
        defaultValue: false
    }

    ConfigurationValue {
        id: disclaimerAccepted
        key: "/disclaimer_accepted"
        defaultValue: false
        onValueChanged: {
            if (value) {
                init()
            }
        }
    }

    ConfigurationValue {
        id: settingAccountUsername
        key: "/account/username"
        defaultValue: ""
    }

    ConfigurationValue {
        id: settingAccountPassword
        key: "/account/password"
        defaultValue: ""
    }

    ConfigurationValue {
        id: settingAccountLoginOnAppStart
        key: "/account/login_on_app_start"
        defaultValue: true
    }

    ConfigurationValue {
        id: settingAccessRestrict
        key: "/access/restrict"
        defaultValue: false
    }

    ConfigurationValue {
        id: settingAccessLockscreenText
        key: "/access/lock_screen/text"
        //% "Please enter your online trading PIN"
        defaultValue: qsTrId("ph-setting-lock-screen-text")
    }

    ConfigurationValue {
        id: settingLockScreenPin
        key: "/access/lock_screen/pin"
        defaultValue: ""
    }

    Component.onCompleted: {
        DownloadCache.cacheDirectory = StandardPaths.cache

        if (restrictAccess) {
            pageStack.push(Qt.resolvedUrl("pages/LockScreenPage.qml"), {}, PageStackAction.Immediate)
        }

        if(disclaimerAccepted.value) {
            init()
        }
    }

    Component.onDestruction: {
        DownloadCache.save()
    }

    DBusInterface {
        bus: DBus.SystemBus
        service: 'com.nokia.mce'
        iface: 'com.nokia.mce.signal'
        path: '/com/nokia/mce/signal'

        signalsEnabled: true

        function tklock_mode_ind(arg) {
            console.debug("tklock_mode_ind=" + arg)
            switch (arg) {
            case "locked":
                if (settingPlaybackPauseOnDeviceLock.value && window.videoPlayerPage) {
                    window.videoPlayerPage.pause()
                }
                pushLockScreenIfNecessary()
                break;
            case "unlocked":
                if (settingPlaybackPauseOnDeviceLock.value && window.videoPlayerPage) {
                    window.videoPlayerPage.resume()
                }
                break;
            }
        }

        function display_status_ind(arg) {
            // Before the device is locked (tklock_mode_ind=locked) it will dimm the
            // display an along with it, deactivate the cover page. This will cause
            // a video paused due to the cover page being active to resume for a couple
            // of seconds until the device reaches locked status.
            // To prevent this from happening, pause video whenever the display
            // is not 'on'.
            console.debug("display_status_ind=" + arg)
            switch (arg) {
            case "on":
                if (_pausedDueToDisplayState) {
                    _pausedDueToDisplayState = false

                    if (window.videoPlayerPage) {
                        window.videoPlayerPage.resume()
                    }
                }
                break;
            default:
                if (!_pausedDueToDisplayState &&
                    settingPlaybackPauseOnDeviceLock.value &&
                    window.videoPlayerPage) {
                    window.videoPlayerPage.pause()
                    _pausedDueToDisplayState = true
                }
                pushLockScreenIfNecessary()
                break;
            }
        }
    }

    /*
When calling Notify() to a display a transient notification, the parameters should be set as follows:

app_name should be a string identifying the sender application, such as the name of its binary, for example. "batterynotifier"
replaces_id should be 0 since the notification is a new one and not related to any existing notification
app_icon should be left empty; it will not be used in this scenario
summary should be left empty for nothing to be shown in the events view
body should be left empty for nothing to be shown in the events view
actions should be left empty
hints should contain the following:
category should be "device" to categorize the notification to be related to the device
urgency should be 2 (critical) to show the notification over the lock screen
transient should be true to automatically close the notification after display
x-nemo-preview-icon should be "icon-battery-low" to define that the icon with that ID is to be shown on the preview banner
x-nemo-preview-body should be "Battery low" in order to show it on the preview banner
expire_timeout should be -1 to let the notification manager choose an appropriate expiration time
*/
    Notification {
        id: notification
        appName: App.displayName
        // file:// prefix not needed!
        appIcon: "/usr/share/icons/hicolor/86x86/apps/harbour-phillis.png"
        icon: appIcon
//        icon: appIcon
        isTransient: true
    }

//    function aboutToQuit() {
//        console.debug("about to quit")
//    }

    function downloadError(url, errorCode, errorMessage) {
        //% "Request failed"
        notification.previewSummary = notification.summary = qsTrId("ph-error-request-failed-summary")
        notification.previewBody = notification.body = errorMessage
        switch (errorCode) {
        case Http.ErrorUrlEmpty:
//            //% "Empty URL"
//            notification.body = qsTrId("error-request-empty-url")
            notification.publish()
            break
        case Http.ErrorRequestFailed:
//            notification.body = errorMessage
            notification.publish()
            break
        }
    }

    function notify(message) {
        notification.previewSummary = notification.summary = message
        notification.body = notification.previewBody = ""
        notification.publish()
    }

    // what to tell the user if a page isn't the one asked for (blocked for the country, a
    // check the app can't pass); "" for ordinary pages
    function problemMessage(html) {
        switch (Scraper.pageProblem(html)) {
        case "geo":
            //% "Pornhub isn't available in your country"
            return qsTrId("ph-error-geo-blocked")
        case "challenge":
            //% "Pornhub asked for a browser check this app can't do. Try again later."
            return qsTrId("ph-error-browser-check")
        default:
            return ""
        }
    }

    function logout() {
        _action = actionLogout
        http.get(Constants.baseUrl + "/user/logout?token=" + encodeURIComponent(logoutToken))
    }

    // fetches the login page for a fresh form token, then sends the account
    function login() {
        if (http.status === Http.StatusRunning) {
            console.debug("login: busy")
            return
        }
        _action = actionLoginPage
        http.get(Constants.baseUrl + "/login")
    }

    function _sendLogin() {
        if (!_loginFields.token) {
            console.debug("no login token on the login page")
        }
        _action = actionLogin
        var headers = {
            "X-Requested-With": "XMLHttpRequest",
            "Accept": "application/json, text/javascript, */*; q=0.01",
            "Origin": Constants.baseUrl,
            "Referer": Constants.baseUrl + "/login",
        }
        http.post(Constants.baseUrl + "/front/authenticate", headers,
                  Scraper.loginBody(_loginFields, settingAccountUsername.value, settingAccountPassword.value))
    }

    function init() {
        cookieJar.clear()
        var nextYear = new Date()
        nextYear.setFullYear(nextYear.getFullYear() + 1)
        // the answer to the site's "I am 18 or older" question, given on the disclaimer page
        cookieJar.addCookie(".pornhub.com", "/", "age_verified", "1", nextYear.getTime(), false)
        cookieJar.addCookie(".pornhub.com", "/", "accessAgeDisclaimerPH", "2", nextYear.getTime(), false)
        _autoLoginTried = false

        reload()
    }

    // reads the login state from any page of the site
    function updateSessionHtml(html) {
        if (!html) {
            return
        }
        if (Scraper.isLoggedIn(html)) {
            _userIsLoggedIn = true
            var token = Scraper.logoutToken(html)
            if (token) {
                logoutToken = token
            }
            if (!_username) {
                _username = Scraper.username(html)
                console.debug("username=" + _username)
            }
        } else if (!isUserLoggedIn) {
            var fields = Scraper.loginFields(html)
            if (fields.token) {
                _loginFields = fields
                loginToken = fields.token
            }
        }
    }

    function reload() {
        _action = actionInit
        http.get(Constants.baseUrl)
    }

    function pushLockScreenIfNecessary() {
        if (restrictAccess && !pageStack.currentPage.isLockScreenPage) {
            pageStack.push(Qt.resolvedUrl("pages/LockScreenPage.qml"), {}, PageStackAction.Immediate)
        }
    }
}
