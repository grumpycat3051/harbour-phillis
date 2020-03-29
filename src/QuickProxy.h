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

#pragma once

#include <QObject>

class QuickProxy : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Proxy proxyType READ proxyType WRITE setProxyType NOTIFY proxyTypeChanged)
    Q_PROPERTY(QString username READ username WRITE setUsername NOTIFY usernameChanged)
    Q_PROPERTY(QString password READ password WRITE setPassword NOTIFY passwordChanged)
    Q_PROPERTY(QString hostname READ hostname WRITE setHostname NOTIFY hostnameChanged)
    Q_PROPERTY(quint16 port READ port WRITE setPort NOTIFY portChanged)
    Q_PROPERTY(bool valid READ valid NOTIFY validChanged)

public:
    enum Proxy
    {
        System,
        Socks5
    };
    Q_ENUM(Proxy)

public:
    QuickProxy(QObject* parent = nullptr);

public:
    Proxy proxyType() const { return m_Type; }
    void setProxyType(Proxy value);
    QString username() const { return m_Username; }
    void setUsername(const QString& value);
    QString password() const { return m_Password; }
    void setPassword(const QString& value);
    QString hostname() const { return m_Hostname; }
    void setHostname(const QString& value);
    quint16 port() const { return m_Port; }
    void setPort(quint16 value);
    bool valid() const;
    Q_INVOKABLE QuickProxy* clone() const;
    Q_INVOKABLE bool isEqualTo(QuickProxy* other) const;
    bool operator==(const QuickProxy& other) const;
    bool operator!=(const QuickProxy& other) const { return !(*this == other); }

signals:
    void proxyTypeChanged();
    void usernameChanged();
    void passwordChanged();
    void hostnameChanged();
    void portChanged();
    void validChanged();

private:
    Proxy m_Type;
    QString m_Username;
    QString m_Password;
    QString m_Hostname;
    quint16 m_Port;
};


