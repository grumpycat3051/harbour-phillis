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

pragma Singleton
import QtQuick 2.0

Item { // Component objects cannot declare new properties.
    readonly property int bearerModeAutoDetect: 0
    readonly property int bearerModeBroadband: 1
    readonly property int bearerModeMobile: 2
    readonly property int format2160: 2160
    readonly property int format1440: 1440
    readonly property int format1080: 1080
    readonly property int format720: 720
    readonly property int format480: 480
    readonly property int format240: 240
    readonly property int formatWorst: -1
    readonly property int formatBest: -2
    readonly property int formatUnknown: -3
    readonly property string baseUrl: "https://www.pornhub.com"
}
