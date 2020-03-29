/* The MIT License (MIT)
 *
 * Copyright (c) 2020 grumpycat <grumpycat3051@protonmail.com>
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

Column {
    id: root

    property Proxy targetProxy: null
    readonly property Proxy currentProxy: _currentProxy
    property Proxy _currentProxy: null

    ComboBox {
        id: proxyTypeComboBox
        enabled: targetProxy
        currentIndex: -1
        width: parent.width

        //% "Proxy type"
        label: qsTrId("ph-proxy-combobox-type-label")

        menu: ContextMenu {
            id: menu
            MenuItem {
                //% "System"
                text: qsTrId("ph-proxy-combobox-system")
            }
            MenuItem {
                //% "SOCKS5"
                text: qsTrId("ph-proxy-combobox-socks5")
            }
        }

        onCurrentIndexChanged: {
            if (targetProxy) {
                switch (currentIndex) {
                case 1:
                    targetProxy.proxyType = Proxy.Socks5
                    proxyDataSectionGroup.enabled = true
                    proxyDataSectionGroup.currentIndex = 0

                    break
                default:
                    targetProxy.proxyType = Proxy.System
                    proxyDataSectionGroup.enabled = false
                    proxyDataSectionGroup.currentIndex = -1
                    break
                }
            } else {
                currentIndex = -1
            }
        }


        function setProxyType(type) {
            switch (type) {
            case Proxy.Socks5:
                currentIndex = 1
                break
            default:
                currentIndex = 0
                break
            }
        }
    }

    ExpandingSectionGroup {
        id: proxyDataSectionGroup

        ExpandingSection {
            width: parent.width
            //% "Proxy data"
            title: qsTrId("ph-proxy-data-section-title")

            content.sourceComponent: Column {
                width: parent.width

                TextField {
                    id: hostnameField
                    enabled: targetProxy
                    //% "Host"
                    label: qsTrId("ph-proxy-data-host-label")
                    placeholderText: label
                    width: parent.width
                    inputMethodHints: Qt.ImhUrlCharactersOnly
                    validator: RegExpValidator { regExp: /^\S.*$/ }
                    //EnterKey.enabled: acceptableInput
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: {
                        portField.focus = true
                    }

                    onTextChanged: {
                        if (targetProxy) {
                            targetProxy.hostname = text
                        }
                    }

                    Component.onCompleted: text = targetProxy.hostname
                }

                TextField {
                    id: portField
                    enabled: targetProxy
                    //% "Port"
                    label: qsTrId("ph-proxy-data-port-label")
                    placeholderText: label
                    width: parent.width
                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                    validator: IntValidator { bottom: 1; top: 65535; }
                    EnterKey.enabled: acceptableInput
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: {
                        usernameField.focus = true
                    }

                    onTextChanged: {
                        if (targetProxy) {
                            targetProxy.port = parseInt(text)
                        }
                    }

                    Component.onCompleted: text = targetProxy.port + ""
                }

                TextField {
                    id: usernameField
                    enabled: targetProxy
                    //% "User"
                    label: qsTrId("ph-proxy-data-user-label")
                    placeholderText: label
                    width: parent.width
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: {
                        passwordField.focus = true
                    }

                    onTextChanged: {
                        if (targetProxy) {
                            targetProxy.username = text
                        }
                    }

                    Component.onCompleted: text = targetProxy.username
                }

                PasswordField {
                    id: passwordField
                    enabled: targetProxy
                    //% "Password"
                    label: qsTrId("ph-proxy-data-password-label")
                    placeholderText: label
                    width: parent.width
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                    EnterKey.onClicked: {
                        passwordField.focus = false
                    }

                    onTextChanged: {
                        if (targetProxy) {
                            targetProxy.password = text
                        }
                    }

                    Component.onCompleted: text = targetProxy.password
                }
            }
        }
    }



    Connections {
        target: App
        onProxyChanged: _updateProxy()
    }

    Component.onCompleted: {
        _updateProxy()
    }

    function _updateProxy() {
        targetProxy = App.proxy.clone()
        _currentProxy = App.proxy.clone()

        proxyTypeComboBox.setProxyType(_currentProxy.proxyType)
    }
}
