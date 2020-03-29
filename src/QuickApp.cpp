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

#include "QuickApp.h"
#include "QuickProxy.h"

#include <QNetworkConfiguration>
#include <QUrl>
#include <QStandardPaths>
#include <QFile>
#include <QDir>
#include <QDebug>
#include <QRegExp>
#include <QUrlQuery>
#include <QNetworkProxy>
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


const QString s_ProxyTypeKey(QLatin1String("/proxy/type"));
const QString s_ProxyUsernameKey(QLatin1String("/proxy/username"));
const QString s_ProxyPasswordKey(QLatin1String("/proxy/password"));
const QString s_ProxyHostnameKey(QLatin1String("/proxy/hostname"));
const QString s_ProxyPortKey(QLatin1String("/proxy/port"));

const QString s_ProxyTypeSocks5Key(QLatin1String("socks5"));

} // anon

QSettings* QuickApp::ms_Settings;

QuickApp::~QuickApp()
{
    delete m_Proxy;
}

QuickApp::QuickApp(QObject* parent)
    : QObject(parent)
{
    connect(&m_NetworkConfigurationManager, &QNetworkConfigurationManager::onlineStateChanged, this, &QuickApp::onOnlineStateChanged);

    loadProxy();
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

void QuickApp::loadProxy()
{
    Q_ASSERT(ms_Settings);

    m_Proxy = new QuickProxy(this);

    const QString type = ms_Settings->value(s_ProxyTypeKey, QString()).toString();
    qDebug("loaded proxy type is \"%s\"\n", qPrintable(type));
    if (s_ProxyTypeSocks5Key == type) {
        m_Proxy->setProxyType(QuickProxy::Socks5);
        m_Proxy->setHostname(ms_Settings->value(s_ProxyHostnameKey, QString()).toString());
        m_Proxy->setUsername(ms_Settings->value(s_ProxyUsernameKey, QString()).toString());
        m_Proxy->setPassword(ms_Settings->value(s_ProxyPasswordKey, QString()).toString());
        m_Proxy->setPort(static_cast<ushort>(ms_Settings->value(s_ProxyPortKey, 0).toUInt()));
    }

    applyProxy(m_Proxy);
}

void QuickApp::saveProxy() const
{
    Q_ASSERT(ms_Settings);
    Q_ASSERT(m_Proxy);

    switch (m_Proxy->proxyType()) {
    case QuickProxy::Socks5:
        qDebug("saving socks5 proxy settings host=%s port=%d ...\n", qPrintable(m_Proxy->hostname()), m_Proxy->port());
        ms_Settings->setValue(s_ProxyTypeKey, s_ProxyTypeSocks5Key);
        break;
    default:
        qDebug("saving system settings proxy\n");
        ms_Settings->setValue(s_ProxyTypeKey, QString());
        break;
    }

    ms_Settings->setValue(s_ProxyHostnameKey, m_Proxy->hostname());
    ms_Settings->setValue(s_ProxyPortKey, m_Proxy->port());
    ms_Settings->setValue(s_ProxyUsernameKey, m_Proxy->username());
    ms_Settings->setValue(s_ProxyPasswordKey, m_Proxy->password());
}

void QuickApp::applyProxy(const QuickProxy* _proxy)
{
    Q_ASSERT(_proxy);

    QNetworkProxy networkProxy;
    networkProxy.setHostName(_proxy->hostname());
    networkProxy.setUser(_proxy->username());
    networkProxy.setPassword(_proxy->password());
    networkProxy.setPort(_proxy->port());
    switch (_proxy->proxyType()) {
    case QuickProxy::Socks5:
        networkProxy.setType(QNetworkProxy::Socks5Proxy);
        qDebug("activating socks5 proxy host=%s port=%d ...\n", qPrintable(networkProxy.hostName()), networkProxy.port());
        break;
    default:
        qDebug("activating system proxy\n");
        break;
    }

    QNetworkProxy::setApplicationProxy(networkProxy);
}

void QuickApp::setProxy(QuickProxy* value)
{
    Q_ASSERT(value);
    if (*m_Proxy != *value) {
        QScopedPointer<QuickProxy> guard(m_Proxy);
        m_Proxy = value;
        m_Proxy->setParent(this);
        emit proxyChanged();

        applyProxy(m_Proxy);
        saveProxy();
    }
}
