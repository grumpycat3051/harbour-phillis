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


var _additionRegex = new RegExp("\\s*\\+\\s*")
var _stringRegex = new RegExp("^[\"']([^\"']*)[\"']$")

// enable tail recursion
function _evaluate(dic, key, strings) {
    if (key in dic) {
        var v = dic[key]
        if (typeof v === "string") {
            var adds = v.split(_additionRegex)
            if (adds.length > 0) {
                for (var i = 0; i < adds.length; ++i) {
                    var token = adds[i]
                    var stringMatch = _stringRegex.exec(token)
                    if (stringMatch) {
                        strings.push(stringMatch[1])
                    } else {
                        _evaluate(dic, token, strings)
                    }
                }
            } else {
                _evaluate(dic, v, strings)
            }
        }
    } else {
        strings.push(key)
    }
}

function evaluate(dic, key) {
    if (key) {
        var strings = []
        _evaluate(dic, key, strings)
        return strings.join("")
    }

    return key
}
