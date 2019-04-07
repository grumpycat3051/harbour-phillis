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

#include <QNetworkDiskCache>
#include <QHash>

class QuickDownloadCache : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString cacheDirectory READ cacheDirectory WRITE setCacheDirectory NOTIFY cacheDirectoryChanged)
    Q_PROPERTY(qint64 cacheSize READ cacheSize WRITE setCacheSize NOTIFY cacheSizeChanged)

public:
    QuickDownloadCache(QObject* parent = nullptr);
    void setCacheDirectory(const QString& dir);
    Q_INVOKABLE void store(const QString& url, const QString& data, int timeoutS);
    Q_INVOKABLE QString load(const QString& url);
    QString cacheDirectory() const { return m_Directory; }
    qint64 cacheSize() const { return m_Cache.cacheSize(); }
    void setCacheSize(qint64 value);
    Q_INVOKABLE void clear();
    Q_INVOKABLE bool save();

signals:
    void cacheDirectoryChanged();
    void cacheSizeChanged();

private:
    struct UrlExpiration
    {
        qint64 storeTime;
        int secondsToExpire;
    };

private:
    void loadCache(QDataStream& ds);
    QString metaFilePath() const;

private:
    QString m_Directory;
    QNetworkDiskCache m_Cache;
    QHash<QString, UrlExpiration> m_UrlStoreTimes;
};
