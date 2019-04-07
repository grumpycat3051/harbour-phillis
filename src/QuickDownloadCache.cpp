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

#include "QuickDownloadCache.h"

#include <QDir>
#include <QFile>
#include <QDebug>
#include <QDataStream>
#include <QDateTime>



QuickDownloadCache::QuickDownloadCache(QObject* parent)
    : QObject(parent)
{

}


void QuickDownloadCache::setCacheDirectory(const QString& dir)
{
    if (dir.isEmpty()) {
        qWarning() << "empty dir";
        return;
    }

    QDir d(dir);
    auto canonicalDir = d.exists() ? d.canonicalPath() : dir;

    if (m_Directory != canonicalDir) {
        m_UrlStoreTimes.clear();
        m_Directory = canonicalDir;
        emit cacheDirectoryChanged();

        const QString filesDirPath = m_Directory + QStringLiteral("/files");
        if (d.mkpath(filesDirPath)) {
            m_Cache.setCacheDirectory(filesDirPath);
            QFile meta(metaFilePath());
            if (meta.open(QIODevice::ReadOnly)) {
                QDataStream ds(&meta);
                loadCache(ds);
            }
        } else {
            qCritical("failed to create directory %s\n", qPrintable(filesDirPath));
        }
    }
}

void QuickDownloadCache::loadCache(QDataStream& ds)
{
    int version, count;
    QString url;
    UrlExpiration e;


    ds >> version;
    if (version != 1) {
        qDebug() << "unhandled version" << version;
        return;
    }

    ds >> count;
    for (int i = 0; i < count; ++i) {
        ds >> url >> e.storeTime >> e.secondsToExpire;
        if (ds.status() != QDataStream::Ok) {
            return;
        }

        m_UrlStoreTimes.insert(url, e);
    }
}

void QuickDownloadCache::clear()
{
    m_Cache.clear();
    m_UrlStoreTimes.clear();
    if (QFile::remove(metaFilePath())) {
        qDebug() << "removed" << metaFilePath();
    }

}

QString QuickDownloadCache::load(const QString& url)
{
    if (url.isEmpty()) {
        qWarning() << "empty url";
        return QString();
    }

    auto it = m_UrlStoreTimes.find(url);
    if (it == m_UrlStoreTimes.end()) {
        m_Cache.remove(url);
        return QString();
    }

    auto s = it.value().secondsToExpire;
    if (s == -1) { // good forever
        auto device = m_Cache.data(url);
        if (device) {
            return QString::fromUtf8(device->readAll());
        } else {
            m_UrlStoreTimes.erase(it);
            return QString();
        }
    } else {
        auto now = QDateTime::currentMSecsSinceEpoch() / 1000;
        if (now > it.value().storeTime + s) {
            m_Cache.remove(url);
            m_UrlStoreTimes.erase(it);
            return QString();
        } else {
            auto device = m_Cache.data(url);
            if (device) {
                return QString::fromUtf8(device->readAll());
            } else {
                m_UrlStoreTimes.erase(it);
                return QString();
            }
        }
    }
    return QString();
}

bool QuickDownloadCache::save()
{
    if (m_Directory.isEmpty()) {
        qWarning() << "directory not set";
        return false;
    }

    QFile f(metaFilePath());
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        {
            QDataStream ds(&f);
            int version = 1;
            ds << version;
            ds << m_UrlStoreTimes.size();
            auto beg = m_UrlStoreTimes.cbegin();
            auto end = m_UrlStoreTimes.cend();
            for (auto it = beg; it != end; ++it) {
                ds << it.key() << it.value().storeTime << it.value().secondsToExpire;
            }

            if (ds.status() != QDataStream::Ok) {
                return false;
            }
        }

        return f.flush();
    }

    return false;
}

void QuickDownloadCache::store(const QString& url, const QString& data, int timeoutS)
{
    if (url.isEmpty()) {
        qWarning() << "empty url";
        return;
    }

    const auto e = UrlExpiration{QDateTime::currentMSecsSinceEpoch() / 1000, timeoutS};
    auto it = m_UrlStoreTimes.find(url);
    if (it == m_UrlStoreTimes.end()) {
        it = m_UrlStoreTimes.insert(url, e);
    } else {
        it.value() = e;
    }

    QNetworkCacheMetaData metaData;
    metaData.setUrl(url);
    metaData.setSaveToDisk(true);
//    metaData.setLastModified(QDateTime::currentDateTimeUtc());
//    metaData.setExpirationDate()
    auto device = m_Cache.prepare(metaData);
    if (device) {
        device->write(data.toUtf8());
        m_Cache.insert(device);
    } else {
        qCritical() << "no device";
    }
}

QString QuickDownloadCache::metaFilePath() const
{
    return m_Directory + QStringLiteral("/meta");
}

void QuickDownloadCache::setCacheSize(qint64 value)
{
    auto previous = cacheSize();
    m_Cache.setMaximumCacheSize(value);
    auto current = cacheSize();
    if (previous != current) {
        emit cacheSizeChanged();
    }
}
