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

#include "QuickCookieJar.h"
#include <QNetworkCookie>
#include <QFile>
#include <QTextStream>
#include <QDateTime>
#include <QDebug>

QuickCookieJar::~QuickCookieJar()
{

}

QuickCookieJar::QuickCookieJar(QObject *parent)
    : QNetworkCookieJar(parent)
{}

bool QuickCookieJar::loadFromNetscapeFormat(const QString& filePath)
{
    QFile f(filePath);
    if (f.open(QIODevice::ReadOnly)) {
        QList<QNetworkCookie> cookies;
        QTextStream reader(&f);
        QTextStream lineParser;
        QString line;
        qint64 expirationDate;
        QString domain;
        QString misc;
        QString path;
        QString secure;
        QString name;
        QString value;
        while (!reader.atEnd()) {
            reader.readLineInto(&line);
            if (line.startsWith(QLatin1Char('#'))) {
                continue;
            }

            lineParser.setString(&line, QIODevice::ReadOnly);


            lineParser >> domain >> misc >> path >> secure >> expirationDate >> name >> value;
            QNetworkCookie cookie;
            cookie.setDomain(domain);
            cookie.setExpirationDate(QDateTime::fromMSecsSinceEpoch(1000 * expirationDate));
            cookie.setSecure(secure.compare(QStringLiteral("TRUE"), Qt::CaseInsensitive) == 0);
            cookie.setPath(path);
            cookie.setName(name.toUtf8());
            cookie.setValue(value.toUtf8());
            cookies << cookie;
        }

        if (reader.status() == QTextStream::Ok) {
            qDebug("succesfully read cookies from  %s\n", qPrintable(filePath));
            setAllCookies(cookies);
            return true;
        }

        qWarning("failed to read data from %s: %s (%d)\n", qPrintable(filePath), qPrintable(f.errorString()), f.error());

    } else {
        qWarning("failed to open %s for writing: %s (%d)\n", qPrintable(filePath), qPrintable(f.errorString()), f.error());
    }

    return false;
}

bool QuickCookieJar::saveToNetscapeFormat(const QString& filePath)
{
    QFile f(filePath);
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        const auto cookies = allCookies();
        const auto beg = cookies.cbegin();
        const auto end = cookies.cend();
        QTextStream writer(&f);
        writer << QStringLiteral("# Netscape HTTP Cookie File\n# http://curl.haxx.se/rfc/cookie_spec.html\n# This is a generated file!  Do not edit.\n");

        for (auto it = beg; it != end; ++it) {
            const auto& cookie = *it;
            writer << cookie.domain() << QLatin1Char('\t')
                   << (cookie.domain().startsWith(QLatin1Char('.')) ? QLatin1Literal("TRUE") : QLatin1Literal("FALSE")) << QLatin1Char('\t')
                   << cookie.path() << QLatin1Char('\t')
                   << cookie.isSecure()  << QLatin1Char('\t')
                   << (cookie.expirationDate().currentMSecsSinceEpoch() / 1000)  << QLatin1Char('\t')
                   << cookie.name()  << QLatin1Char('\t')
                   << cookie.value() << QLatin1Char('\n');
        }

        writer.flush();

        if (writer.status() == QTextStream::Ok && f.flush()) {
            qDebug("saved cookies to %s\n", qPrintable(filePath));
            return true;
        } else {
            qWarning("failed to write cookies to %s: %s (%d)\n", qPrintable(filePath), qPrintable(f.errorString()), f.error());
        }
    } else {
        qWarning("failed to open %s for writing: %s (%d)\n", qPrintable(filePath), qPrintable(f.errorString()), f.error());
    }

    return false;
}

void QuickCookieJar::dump()
{

    const auto cookies = allCookies();
    qDebug() << "#" << cookies.size();
    const auto beg = cookies.cbegin();
    const auto end = cookies.cend();
    for (auto it = beg; it != end; ++it) {
        qDebug() << *it;
    }
}

void QuickCookieJar::clear()
{
    qDebug() << "clearing cookies";
    setAllCookies(QList<QNetworkCookie>());
}

bool QuickCookieJar::addCookie(
            const QString& domain,
            const QString& path,
            const QString& name,
            const QString& value,
            qint64 msSinceTheEpoch,
        bool isSecure) {
    QNetworkCookie cookie;
    cookie.setDomain(domain);
    cookie.setExpirationDate(QDateTime::fromMSecsSinceEpoch(msSinceTheEpoch));
    cookie.setHttpOnly(false);
    cookie.setName(name.toUtf8());
    cookie.setPath(path);
    cookie.setSecure(isSecure);
    cookie.setValue(value.toUtf8());

    auto result = insertCookie(cookie);
    if (result) {
        qDebug() << "added" << cookie;
    } else {
        qDebug() << "failed to add" << cookie;
    }

    return result;
}
