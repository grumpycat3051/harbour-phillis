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

#pragma once

#include <QNetworkCookieJar>

class QuickCookieJar : public QNetworkCookieJar
{
    Q_OBJECT
public:
    virtual ~QuickCookieJar();
    explicit QuickCookieJar(QObject *parent = nullptr);

    Q_INVOKABLE bool loadFromNetscapeFormat(const QString& filePath);
    Q_INVOKABLE bool saveToNetscapeFormat(const QString& filePath);
    Q_INVOKABLE void dump();
    Q_INVOKABLE void clear();
    Q_INVOKABLE bool addCookie(
            const QString& domain,
            const QString& path,
            const QString& name,
            const QString& value,
            qint64 msSinceTheEpoch,
            bool isSecure);
};
