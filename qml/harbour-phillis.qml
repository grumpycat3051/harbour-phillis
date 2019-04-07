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
import Nemo.Configuration 1.0
import Nemo.DBus 2.0
import Nemo.Notifications 1.0
import grumpycat 1.0
import "."

ApplicationWindow
{
    id: window
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    initialPage: Qt.resolvedUrl("pages/StartPage.qml")
    allowedOrientations: defaultAllowedOrientations

    property bool _pausedDueToDisplayState: false
    property var videoPlayerPage
    property string loginToken
    property string logoutToken
    readonly property var logoutTokenRegex: new RegExp("href=\"/user/logout\\?token=([^\"]+)\"")
    readonly property var loginTokenRegex: new RegExp("<input\\s+type=\"hidden\"\\s+name=\"token\"\\s+value=\"([^\"]+)\"\\s*/>")
    readonly property bool isUserLoggedIn: _userIsLoggedIn
    property bool _userIsLoggedIn: false
    property string pin
    readonly property bool restrictAccess: settingAccessRestrict.value && pin
    readonly property bool hasLoginData: settingAccountUsername.value && settingAccountPassword.value && loginToken
    readonly property bool canAutoLogin: settingAccountLoginOnAppStart.value && hasLoginData

    property int _action: -1
    readonly property int actionInit: 0
    readonly property int actionLogin: 1
    readonly property int actionLogout: 2

    Http {
        id: http
        onStatusChanged: {
            switch (status) {
            case Http.StatusCompleted:
                console.debug("completed error=" + error)
                if (Http.ErrorNone === error) {
                    cookieJar.dump()
                    switch (_action) {
                    case actionLogout:
                        _userIsLoggedIn = false
                        loginToken = ""
                        var line = data.replace(new RegExp("\r|\n", "g"), " ") // Qt doesn't have 's' flag to match newlines with .
                        scanForLoginTokenInLine(line)
                        break
                    case actionLogin:
                        try {
                            var jsonObject = JSON.parse(data)
                            if (jsonObject.success === "1") {
                                _userIsLoggedIn = true
                                console.debug("login success")
                                //% "Login success"
                                window.notify(qsTrId("login-succes-message"))

                                // load a page to have logout token for menu
                                // weirdly this doens't work if using the base page
                                _action = actionInit
                                http.get(Constants.baseUrl + "/categories")
                            } else {
                                _userIsLoggedIn = false
                                window.notify(jsonObject.message)
                            }
                        } catch (error) {
                            console.debug("response data")
                            console.debug(data)
                            _userIsLoggedIn = false
                        }
                        break
                    case actionInit: {
                        var line = data.replace(new RegExp("\r|\n", "g"), " ") // Qt doesn't have 's' flag to match newlines with .
                        updateSessionHtml(line)
                        if (isUserLoggedIn && !logoutToken) {
                            console.debug(data)
                        }

//                        var want = 2
//                        var hasLoginToken = false
//                        var hasLogoutToken = false
//                        var lines = data.split('\n');
//                        for (var i = 0; i < lines.length && want > 0; ++i) {
//                            var line = lines[i]
//                            if (!hasLoginToken && scanForLoginTokenInLine(line)) {
//                                hasLoginToken = true
//                                --want
//                                console.debug("login token=" + loginToken)
//                            }

//                            if (!hasLogoutToken && scanForLogoutTokenInLine(line)) {
//                                hasLogoutToken = true
//                                --want
//                                console.debug("logout token=" + logoutToken)
//                            }
//                        }

                        if (!isUserLoggedIn && canAutoLogin) {
                            login()
                        }
                    } break
                    }
                } else {
                    switch (_action) {
                    case actionLogin:
                    case actionLogout:
                        console.debug("response data")
                        console.debug(data)
                        break
                    case actionInit:
                        //% "Initial loading of website failed"
                        var str = qsTrId("error-message-initial-request-failed")
                        downloadError(url, error, str)
                        break
                    default:
                        downloadError(url, error, errorMessage)
                        break
                    }
                }
                break
            }
        }
    }

    ConfigurationGroup {
        id: settings

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
        }

        ConfigurationValue {
            id: settingDisplayCategoriesPerRow
            defaultValue: 1
            key: "/display/categories/items_per_grid_row"
        }

        ConfigurationValue {
            id: settingDisplayPornstarsPerRow
            defaultValue: 2
            key: "/display/pornstars/items_per_grid_row"
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
                    pageStack.pop()
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
            key: "/access/lock_screen_text"
            //% "Please enter your online trading PIN"
            defaultValue: qsTrId("setting-lock-screen-text")
        }
    }

    Component.onCompleted: {
        DownloadCache.cacheDirectory = StandardPaths.cache
        pin = loadPin()

        if (!disclaimerAccepted.value) {
            pageStack.push(Qt.resolvedUrl("pages/AdultContentDisclaimerPage.qml"), {}, PageStackAction.Immediate)
        }

        if (restrictAccess) {
            pageStack.push(Qt.resolvedUrl("pages/LockScreenPage.qml"), {}, PageStackAction.Immediate)
        }

        init()
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
        notification.previewSummary = notification.summary = qsTrId("error-request-failed-summary")
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

    function scanForLogoutTokenInLine(line, callback) {
        var logoutTokenMatch = logoutTokenRegex.exec(line)
        if (logoutTokenMatch) {
            logoutToken = logoutTokenMatch[1]
            if (callback) {
                callback(logoutToken)
            }
            return true
        }

        return false
    }

    function scanForLoginTokenInLine(line, callback) {
        var match = loginTokenRegex.exec(line)
        if (match) {
            loginToken = match[1]
            if (callback) {
                callback(loginToken)
            }
            return true
        }

        return false
    }



    function logout() {
        _action = actionLogout
        cookieJar.dump()
        http.get(Constants.baseUrl + "/user/logout?token=" + logoutToken)
    }

    function login() {
        _action = actionLogin
        cookieJar.dump()
        var postData = App.urlEncode({
                                         username: settingAccountUsername.value,
                                         password: settingAccountPassword.value,
                                         remember_me: 1,
                                         token: loginToken,
                                     })
        http.post(Constants.baseUrl + "/front/authenticate", postData)
    }

    function init() {
        cookieJar.clear()
        var tomorrow = new Date()
        tomorrow.setDate(tomorrow.getDate() + 1)
        cookieJar.addCookie(".pornhub.com", "/", "accessAgeDisclaimerPH", "1", tomorrow.getTime(), false)
        reload()
    }

    function updateSessionHtml(htmlLine) {
        if (isUserLoggedIn) {
            if (scanForLogoutTokenInLine(htmlLine)) {
                console.debug("logout token=" + logoutToken)
            } else {
                console.debug("logout token not found despite being logged in")
            }
        } else {
            if (scanForLoginTokenInLine(htmlLine)) {
                console.debug("login token=" + loginToken)
            } else {
                console.debug("login token not found despite being logged out")
            }
        }
    }

    function updateSessionLine(htmlLine) {
        if (isUserLoggedIn) {
            if (scanForLogoutTokenInLine(htmlLine)) {
                console.debug("logout token=" + logoutToken)
                return true
            }
        } else {
            if (scanForLoginTokenInLine(htmlLine)) {
                console.debug("login token=" + loginToken)
                return true
            }
        }

        return false
    }

    function loadPin() {
        return "" + App.settingsRead("access", "pin", "")
    }

    function savePin(pin) {
        App.settingsWrite("access", "pin", pin)
    }

    function reload() {
        _action = actionInit
        http.get(Constants.baseUrl)
    }
}
