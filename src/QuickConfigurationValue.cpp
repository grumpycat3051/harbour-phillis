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


#include "QuickConfigurationValue.h"

#include <QSettings>
#include <QDebug>

QSettings* QuickConfigurationValue::ms_Settings;

QuickConfigurationValue::QuickConfigurationValue(QObject *parent)
    : QObject(parent)
{

}

QVariant QuickConfigurationValue::value()
{
    Q_ASSERT(ms_Settings);

    if (m_Key.isEmpty()) {
        qWarning("no key set\n");
        return QVariant();
    }

    if (!m_DefaultValue.isValid()) {
        qWarning("set default value for typing\n");
        return QVariant();
    }

    if (!m_Value.isValid()) {
        auto v = ms_Settings->value(m_Key, m_DefaultValue);
        if (v.convert(m_DefaultValue.type())) {
            qDebug("load key %s type %s\n", qPrintable(m_Key), v.typeName());
            m_Value = v;
        } else {
            qWarning("failed to convert from %s to %s\n", v.typeName(), m_DefaultValue.typeName());
            m_Value = m_DefaultValue;
        }
    }

    return m_Value;
}

void QuickConfigurationValue::setValue(const QVariant& _value)
{
    if (m_Key.isEmpty()) {
        qWarning("no key set\n");
        return;
    }

    if (!m_DefaultValue.isValid()) {
        qWarning("set default value for typing\n");
        return;
    }

    QVariant converted(_value);
    if (!converted.convert(m_DefaultValue.type())) {
        qWarning("failed to convert from %s to %s\n", _value.typeName(), m_DefaultValue.typeName());
        return;
    }

    if (converted != value()) {
        m_Value = converted;
        Q_ASSERT(ms_Settings);
        ms_Settings->setValue(m_Key, m_Value);
        qDebug("save key %s type %s\n", qPrintable(m_Key), m_Value.typeName());
        emit valueChanged();
    }
}
