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

#include "QuickProxy.h"

QuickProxy::QuickProxy(QObject* parent)
    : QObject(parent)
    , m_Type(System)
    , m_Port(0)
{
}

void QuickProxy::setProxyType(Proxy value)
{
    if (m_Type != value) {
        m_Type = value;
        emit proxyTypeChanged();
        emit validChanged();
    }
}

void QuickProxy::setUsername(const QString& value)
{
    if (m_Username != value) {
        m_Username = value;
        emit usernameChanged();
        emit validChanged();
    }
}

void QuickProxy::setPassword(const QString& value)
{
    if (m_Password != value) {
        m_Password = value;
        emit passwordChanged();
        emit validChanged();
    }
}

void QuickProxy::setHostname(const QString& value)
{
    if (m_Hostname != value) {
        m_Hostname = value;
        emit hostnameChanged();
        emit validChanged();
    }
}

void QuickProxy::setPort(quint16 value)
{
    if (m_Port != value) {
        m_Port = value;
        emit portChanged();
        emit validChanged();
    }
}

QuickProxy* QuickProxy::clone() const
{
    QuickProxy* result = new QuickProxy;

    result->setProxyType(m_Type);
    result->setHostname(m_Hostname);
    result->setUsername(m_Username);
    result->setPassword(m_Password);
    result->setPort(m_Port);

    return result;
}

bool QuickProxy::isEqualTo(QuickProxy* other) const
{
    if (!other) {
        return false;
    }

    if (this == other) {
        return true;
    }

    return *this == *other;
}

bool QuickProxy::operator==(const QuickProxy& other) const
{
    if (m_Type != other.m_Type) {
        return false;
    }

    switch (m_Type) {
    default:
        return true;
    case Socks5:
        return m_Hostname == other.m_Hostname &&
                m_Port == other.m_Port &&
                m_Username == other.m_Username &&
                m_Password == other.m_Password;
    }
}

bool QuickProxy::valid() const
{
    switch (m_Type) {
    default:
        return true;
    case Socks5:
        return !m_Hostname.isEmpty() && m_Port > 0;
    }
}
