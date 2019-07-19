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

#include <QObject>
#include <QVariant>

class QSettings;

class QuickConfigurationValue : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString key READ key WRITE setKey)
    Q_PROPERTY(QVariant defaultValue READ defaultValue WRITE setDefaultValue)
    Q_PROPERTY(QVariant value READ value WRITE setValue NOTIFY valueChanged)
public:
    explicit QuickConfigurationValue(QObject *parent = nullptr);

public:
    static void SetSettings(QSettings* value) { ms_Settings = value; }

public:
    QString key() const { return m_Key; }
    void setKey(const QString& value) { m_Key = value; }
    QVariant defaultValue() const { return m_DefaultValue; }
    void setDefaultValue(const QVariant& value) { m_DefaultValue = value; }
    QVariant value();
    void setValue(const QVariant& value);

signals:
    void valueChanged();

private:
    QString m_Key;
    QVariant m_DefaultValue, m_Value;

private:
    static QSettings* ms_Settings;
};
