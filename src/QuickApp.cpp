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

#include "QuickApp.h"

#include <QNetworkConfiguration>
#include <QUrl>
#include <QStandardPaths>
#include <QFile>
#include <QDir>
#include <QDebug>
#include <QRegExp>
#include <QUrlQuery>
#include <QSettings>

namespace
{
const QRegExp htmlEntityScanner("&(nbsp|amp|lt|gt|quot|apos|#\\d+);");
const QHash<QString, QString> htmlEntityReplacements = {
    { QStringLiteral("&nbsp;"), QStringLiteral(" ") },
    { QStringLiteral("&amp;"), QStringLiteral("&") },
    { QStringLiteral("&lt;"), QStringLiteral("<") },
    { QStringLiteral("&gt;"), QStringLiteral(">") },
    { QStringLiteral("&quot;"), QStringLiteral("\"") },
    { QStringLiteral("&apos;"), QStringLiteral("'") },

};
}

QuickApp::QuickApp(QObject* parent)
    : QObject(parent)
{
    connect(&m_NetworkConfigurationManager, &QNetworkConfigurationManager::onlineStateChanged, this, &QuickApp::onOnlineStateChanged);
}

QString
QuickApp::version() const
{
    return QStringLiteral(QT_STRINGIFY(PHILLIS_VERSION_MAJOR) "." QT_STRINGIFY(PHILLIS_VERSION_MINOR) "." QT_STRINGIFY(PHILLIS_VERSION_PATCH));
}

QString
QuickApp::displayName() const
{
    return QStringLiteral("PHillis");
}

bool
QuickApp::isOnBroadband() const
{
    auto configs = m_NetworkConfigurationManager.allConfigurations(QNetworkConfiguration::Active);
    foreach (const auto& config, configs) {
        if (config.isValid()) {
            switch (config.bearerTypeFamily()) {
            case QNetworkConfiguration::BearerEthernet:
            case QNetworkConfiguration::BearerWLAN:
                return true;
            default:
                break;
            }
        }
    }

    return false;
}

bool
QuickApp::isOnMobile() const
{
    auto configs = m_NetworkConfigurationManager.allConfigurations(QNetworkConfiguration::Active);
    foreach (const auto& config, configs) {
        if (config.isValid()) {
            switch (config.bearerTypeFamily()) {
            case QNetworkConfiguration::Bearer2G:
            case QNetworkConfiguration::Bearer3G:
            case QNetworkConfiguration::Bearer4G:
                return true;
            default:
                break;
            }
        }
    }

    return false;
}


bool
QuickApp::isOnline() const
{
    return m_NetworkConfigurationManager.isOnline();
}

void
QuickApp::onOnlineStateChanged(bool online)
{
    Q_UNUSED(online)
    emit isOnlineChanged();
}

bool
QuickApp::isUrl(const QString& str) const
{
    QUrl url(str);
    return url.isValid();
}

QString QuickApp::appDir() const
{
    return QStringLiteral(QT_STRINGIFY(PHILLIS_DATADIR));
}

bool QuickApp::unlink(const QString& filePath) const
{
    return QFile::remove(filePath);
}

bool QuickApp::copy(const QString& srcFilePath, const QString& dstFilePath) const
{
    return QFile::copy(srcFilePath, dstFilePath);
}

bool QuickApp::move(const QString& srcFilePath, const QString& dstFilePath) const
{
    return QFile::rename(srcFilePath, dstFilePath);
}

bool QuickApp::isDir(const QString& str) const
{
    QDir d(str);
    return d.exists();
}

QString QuickApp::replaceHtmlEntities(const QString& input)
{
    auto result = QString();
    auto start = 0, end = 0;
    while ((end = htmlEntityScanner.indexIn(input, start)) != -1) {
        result += input.mid(start, end - start);
        auto match = htmlEntityScanner.cap(0);
        if (match[1] == QLatin1Char('#')) {
            // &#0*60 -> <
            auto code = match.mid(2, match.size() - 3).toInt();
            result += QLatin1Char(code);
        } else {
            result += htmlEntityReplacements.value(match);
        }

        start += end + match.size();
    }

    end = input.size();

    if (start < end) {
        result += input.mid(start, end - start);
    }

    return result;
}

QString QuickApp::urlEncode(const QVariantMap& kv)
{
    QUrlQuery q;
    const auto beg = kv.cbegin();
    const auto end = kv.cend();
    for (auto it = beg; it != end; ++it) {
        q.addQueryItem(it.key(), it.value().toString());
    }

    return q.toString(QUrl::FullyEncoded);
}

QVariant QuickApp::settingsRead(const QString& section, const QString& key, const QVariant& defaultValue)
{
    QSettings settings;
    settings.beginGroup(section);
    return settings.value(key, defaultValue);
}

bool QuickApp::settingsWrite(const QString& section, const QString& key, const QVariant& value)
{
    QSettings settings;
    settings.beginGroup(section);
    if (value.isValid()) {
        settings.setValue(key, value);
    } else {
        settings.remove(key);
    }
    settings.endGroup();
    settings.sync();
    return QSettings::NoError == settings.status();
}
