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

    SilicaFlickable {
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: column.height

        VerticalScrollDecorator {}

        Column {
            id: column
            width: parent.width

            PageHeader {
                id: header
                //% "Settings"
                title: qsTrId("ph-settings-page-header")
            }

            SectionHeader {
                //% "Network"
                text: qsTrId("ph-settings-page-network-header")
            }

            ComboBox {
                id: bearerModeComboBox
                width: parent.width
                //% "Network connection type"
                label: qsTrId("ph-settings-page-network-connection-type")
                menu: ContextMenu {
                    MenuItem {
                        //% "Autodetect"
                        text: qsTrId("ph-settings-page-network-connection-autodetect")
                    }
                    MenuItem {
                        //% "Broadband"
                        text: qsTrId("ph-settings-page-network-connection-broadband")
                    }
                    MenuItem {
                        //% "Mobile"
                        text: qsTrId("ph-settings-page-network-connection-mobile")
                    }
                }

                Component.onCompleted: currentIndex = settingBearerMode.value

                onCurrentIndexChanged: {
    //                console.debug("bearer mode onCurrentIndexChanged " + currentIndex)
                    settingBearerMode.value = currentIndex
                }
            }

            ProxyComboBox {
                id: proxy
                width: parent.width
            }

            ButtonLayout {
                width: parent.width
                Button {
                    enabled: {
                        if (proxy.targetProxy) {
                            if (proxy.targetProxy.valid) {
                                if (proxy.currentProxy) {
                                    if (proxy.currentProxy.valid) {
                                        return !proxy.targetProxy.isEqualTo(proxy.currentProxy)
                                    } else {
                                        return true
                                    }
                                } else {
                                    return true
                                }
                            } else {
                                return false
                            }
                        } else {
                            return false
                        }
                    }

                    //% "Apply"
                    text: qsTrId("ph-settings-page-network-apply-proxy-settings")
                    onClicked: App.proxy = proxy.targetProxy
                }
            }

            SectionHeader {
                //% "Format"
                text: qsTrId("ph-format-label")
            }

            FormatComboBox {
                //% "Broadband"
                label: qsTrId("ph-settings-page-network-broadband-label")
                format: settingBroadbandDefaultFormat.value
                onFormatChanged: {
                    console.debug("broadband format=" + format)
                    if (format !== Constants.formatUnknown) {
                        settingBroadbandDefaultFormat.value = format
                    }
                }

                Component.onCompleted: console.debug("broadband format=" + format)
            }

            FormatComboBox {
                //% "Mobile"
                label: qsTrId("ph-settings-page-network-mobile-label")
                format: settingMobileDefaultFormat.value
                onFormatChanged: {
                    console.debug("mobile format=" + format)
                    if (format !== Constants.formatUnknown) {
                        settingMobileDefaultFormat.value = format
                    }
                }

                Component.onCompleted: console.debug("mobile format=" + format)
            }

            SectionHeader {
                //% "Content Preferences"
                text: qsTrId("ph-settings-page-content-preferences-section-header")
            }

            Column {
                width: parent.width
                spacing: Theme.paddingMedium

                IconTextSwitch {
                    //% "Gay Only"
                    text: qsTrId("ph-settings-page-content-preferences-gay-only-switch-text")
                    //% "Only show gay categories and videos"
                    description: qsTrId("ph-settings-page-content-preferences-gay-only-switch-description")
                    icon.source: "file://" + App.appDir + "/media/gay.png"
                    icon.width: Theme.iconSizeSmall
                    icon.height: Theme.iconSizeSmall
                    icon.sourceSize.width: icon.width
                    icon.sourceSize.height: icon.height
                    icon.fillMode: Image.PreserveAspectFit
                    checked: settingGayOnly.value
                    onClicked: {
                        settingGayOnly.value = !settingGayOnly.value
                    }
                }
            }

            SectionHeader {
                //% "Playback"
                text: qsTrId("ph-settings-page-playback-section-header")
            }

            TextSwitch {
                //% "Pause playback on device lock"
                text: qsTrId("ph-settings-page-playback-pause-on-device-lock-switch")
                checked: settingPlaybackPauseOnDeviceLock.value
                onClicked: {
                    settingPlaybackPauseOnDeviceLock.value = !settingPlaybackPauseOnDeviceLock.value
                    console.debug("continue playback on device lock=" + checked)
                }
            }

            TextSwitch {
                //% "Pause playback when the cover page is shown"
                text: qsTrId("ph-settings-page-playback-pause-if-cover-page-switch")
                checked: settingPlaybackPauseInCoverMode.value
                onClicked: {
                    settingPlaybackPauseInCoverMode.value = !settingPlaybackPauseInCoverMode.value
                    console.debug("continue playback in cover mode=" + checked)
                }
            }

            TextField {
                width: root.width
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                //% "Attempts to reload video on playback error"
                label: qsTrId("ph-settings-page-playback-video-reload-attempts")
                text: settingPlaybackVideoReloadAttempts.value
                EnterKey.enabled: acceptableInput
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: focus = false
                validator: IntValidator {
                    bottom: 0
                }

                onTextChanged: {
                    console.debug("text: " + text)
                    if (acceptableInput) {
                        var number = parseInt(text)
                        console.debug("number: " + number)
                        if (typeof(number) === "number") {
                            settingPlaybackVideoReloadAttempts.value = number
                        }
                    }
                }
            }

            SectionHeader {
                //% "Display"
                text: qsTrId("ph-settings-page-display")
            }

            TextField {
                width: root.width
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                //% "Videos per row"
                label: qsTrId("ph-settings-page-display-videos-per-grid-row")
                text: settingDisplayVideosPerRow.value
                EnterKey.enabled: acceptableInput
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: focus = false
                validator: IntValidator {
                    bottom: 1
                }

                onTextChanged: {
                    console.debug("text: " + text)
                    if (acceptableInput) {
                        var number = parseInt(text)
                        console.debug("number: " + number)
                        if (typeof(number) === "number") {
                            settingDisplayVideosPerRow.value = number
                        }
                    }
                }
            }

            TextField {
                width: parent.width
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                //% "Categories per row"
                label: qsTrId("ph-settings-page-display-categories-per-grid-row")
                text: settingDisplayCategoriesPerRow.value
                EnterKey.enabled: acceptableInput
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: focus = false
                validator: IntValidator {
                    bottom: 1
                }

                onTextChanged: {
                    console.debug("text: " + text)
                    if (acceptableInput) {
                        var number = parseInt(text)
                        console.debug("number: " + number)
                        if (typeof(number) === "number") {
                            settingDisplayCategoriesPerRow.value = number
                        }
                    }
                }
            }

            TextField {
                width: root.width
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                //% "Pornstars per row"
                label: qsTrId("ph-settings-page-display-pornstars-per-grid-row")
                text: settingDisplayPornstarsPerRow.value
                EnterKey.enabled: acceptableInput
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: focus = false
                validator: IntValidator {
                    bottom: 1
                }

                onTextChanged: {
                    console.debug("text: " + text)
                    if (acceptableInput) {
                        var number = parseInt(text)
                        console.debug("number: " + number)
                        if (typeof(number) === "number") {
                            settingDisplayPornstarsPerRow.value = number
                        }
                    }
                }
            }

            TextSwitch {
                //% "Add one extra column in landscape orientation"
                text: qsTrId("ph-settings-page-display-extra-landscape-column")
                checked: settingDisplayExtraLandscapeColumn.value
                onClicked: {
                    settingDisplayExtraLandscapeColumn.value = !settingDisplayExtraLandscapeColumn.value
                    console.debug("display extra landscape column=" + checked)
                }
            }

            SectionHeader {
                //% "Access"
                text: qsTrId("ph-settings-page-access")
            }

            TextSwitch {
                //% "Require a PIN to access the app"
                text: qsTrId("ph-settings-page-access-restrict-text")
                //% "Protect against accidently accessing the application. The PIN will be stored as plain text in the application configuration directory. Should you forget your PIN simply delete the file to restore access to the application."
                description: qsTrId("ph-settings-page-access-restrict-description")
                checked: settingAccessRestrict.value
                onClicked: {
                    settingAccessRestrict.value = !settingAccessRestrict.value
                    if (settingAccessRestrict.value) {
                        pinField.focus = true
                    }
                }
            }

            TextField {
                id: pinField
                width: root.width
                enabled: settingAccessRestrict.value
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                //% "PIN"
                label: qsTrId("ph-settings-page-access-require-pin-label")
                //% "Enter four or more digits"
                placeholderText: qsTrId("ph-settings-page-access-require-pin-placeholder")
                validator: RegExpValidator { regExp: /^\d{4,}$/ }
                text: settingLockScreenPin.value
                EnterKey.enabled: acceptableInput
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: {
                    focus = false
                    settingLockScreenPin.value = text
                }
            }

            TextField {
                width: root.width
                enabled: settingAccessRestrict.value
                //% "Lock screen text"
                label: qsTrId("ph-settings-page-access-lock-screen-text")
                validator: RegExpValidator { regExp: /^.+$/ }
                text: settingAccessLockscreenText.value
                EnterKey.enabled: acceptableInput
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: {
                    focus = false
                    settingAccessLockscreenText.value = text
                }
            }

            SectionHeader {
                //% "Account"
                text: qsTrId("ph-settings-page-account")
            }

            TextField {
                //% "Username"
                label: qsTrId("ph-settings-page-account-username")
                placeholderText: label
                width: parent.width
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: {
                    passwordField.focus = true
                    settingAccountUsername.value = text
                }

                text: settingAccountUsername.value
            }

            PasswordField {
                id: passwordField
                width: parent.width
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: {
                    passwordField.focus = false
                    settingAccountPassword.value = text
                }

                text: settingAccountPassword.value
            }

            TextSwitch {
                //% "Login on application start"
                text: qsTrId("ph-settings-page-account-auto-login")
                checked: settingAccountLoginOnAppStart.value
                onClicked: {
                    settingAccountLoginOnAppStart.value = !settingAccountLoginOnAppStart.value
                }
            }

            Item {
                // dummy item to have some space at bottom of the page
                width: root.width
                height: Theme.paddingLarge
            }

            Column {
                visible: debugApp.value
                width: parent.width

                SectionHeader {
                    text: "Debug"
                }

                TextSwitch {
                    text: "video player"
                    checked: window.debugVideoPlayer
                    onClicked: {
                        window.debugVideoPlayer = !window.debugVideoPlayer
                    }
                }
            }
        }
    }
}

