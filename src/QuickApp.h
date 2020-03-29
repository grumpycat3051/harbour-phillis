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

#pragma once

#include <QObject>
#include <QNetworkConfigurationManager>

class QuickProxy;
class QSettings;

class QuickApp : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString version READ version CONSTANT)
    Q_PROPERTY(QString displayName READ displayName CONSTANT)
    Q_PROPERTY(bool isOnBroadband READ isOnBroadband NOTIFY isOnBroadbandChanged)
    Q_PROPERTY(bool isOnMobile READ isOnMobile NOTIFY isOnMobileChanged)
    Q_PROPERTY(bool isOnline READ isOnline NOTIFY isOnlineChanged)
    Q_PROPERTY(QString appDir READ appDir CONSTANT)
    Q_PROPERTY(QuickProxy* proxy READ proxy WRITE setProxy NOTIFY proxyChanged)

public:
    virtual ~QuickApp();
    QuickApp(QObject* parent = nullptr);

public:
    static void SetSettings(QSettings* value) { ms_Settings = value; }

public:
    QString version() const;
    QString displayName() const;
    QString appDir() const;
    QString configDir() const;
    bool isOnBroadband() const;
    bool isOnMobile() const;
    bool isOnline() const;
    QuickProxy* proxy() const { return m_Proxy; }
    void setProxy(QuickProxy* value);
    Q_INVOKABLE bool isUrl(const QString& str) const;
    Q_INVOKABLE bool unlink(const QString& filePath) const;
    Q_INVOKABLE bool copy(const QString& srcFilePath, const QString& dstFilePath) const;
    Q_INVOKABLE bool move(const QString& srcFilePath, const QString& dstFilePath) const;
    Q_INVOKABLE bool isDir(const QString& str) const;
    Q_INVOKABLE QString replaceHtmlEntities(const QString& input);
    Q_INVOKABLE QString urlEncode(const QVariantMap& kv);

signals:
    void isOnBroadbandChanged();
    void isOnMobileChanged();
    void isOnlineChanged();
    void proxyChanged();

private slots:
    void onOnlineStateChanged(bool online);

private:
    void loadProxy();
    void saveProxy() const;
    static void applyProxy(const QuickProxy* proxy);

private:
    QNetworkConfigurationManager m_NetworkConfigurationManager;
    QuickProxy* m_Proxy;

private:
    static QSettings* ms_Settings;
};
