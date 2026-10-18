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
#include <QVariantMap>

class QNetworkAccessManager;
class QNetworkReply;
class QNetworkRequest;
class QuickHttp : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Status status READ status NOTIFY statusChanged)
    Q_PROPERTY(Error error READ error NOTIFY errorChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)
    Q_PROPERTY(QString data READ data NOTIFY dataChanged)
    Q_PROPERTY(QString userAgent READ userAgent WRITE setUserAgent NOTIFY userAgentChanged)
    Q_PROPERTY(QString url READ url /*WRITE setUrl */NOTIFY urlChanged)
    Q_PROPERTY(QNetworkAccessManager* networkAccessManager READ networkAccessManager WRITE setNetworkAccessManager NOTIFY networkAccessManagerChanged)
    Q_PROPERTY(int httpStatusCode READ httpStatusCode NOTIFY httpStatusCodeChanged)
    // address of the last answer, after redirections
    Q_PROPERTY(QString finalUrl READ finalUrl NOTIFY finalUrlChanged)
    // extra request headers sent with every request of this object
    Q_PROPERTY(QVariantMap headers READ headers WRITE setHeaders NOTIFY headersChanged)

public:
    enum Status
    {
        StatusNone,
        StatusRunning,
        StatusCompleted
    };
    Q_ENUM(Status)

    enum Error
    {
        ErrorNone,
        ErrorUrlEmpty,
        ErrorCanceled,
        ErrorRequestFailed,
    };
    Q_ENUM(Error)

public:
    virtual ~QuickHttp();
    QuickHttp(QObject* parent = nullptr);

public:
    static QString UserAgent() { return ms_UserAgent; }
    static void SetUserAgent(const QString& value) { ms_UserAgent = value; }
    static QNetworkAccessManager* NetworkAccessManager() { return ms_NetworkAccessManager; }
    static void SetNetworkAccessManager(QNetworkAccessManager* value) { ms_NetworkAccessManager = value; }
    // headers sent with every request of every object, before the object's own
    static void SetDefaultHeaders(const QVariantMap& value) { ms_DefaultHeaders = value; }
    Q_INVOKABLE void get(const QString& url = QString());
    // a request with extra headers for just this request (kept for its redirections)
    Q_INVOKABLE void get(const QString& url, const QVariantMap& requestHeaders);
    Status status() const { return m_Status; }
    Error error() const { return m_Error; }
    QString errorMessage() const { return m_ErrorMessage; }
    QString data() const { return m_Data; }
    QString userAgent() const;
    void setUserAgent(const QString& value);
    QNetworkAccessManager* networkAccessManager() const;
    void setNetworkAccessManager(QNetworkAccessManager* value);
    QString url() const { return m_Url; }
    int httpStatusCode() const { return m_HttpStatusCode; }
    QString finalUrl() const { return m_FinalUrl; }
    QVariantMap headers() const { return m_Headers; }
    void setHeaders(const QVariantMap& value);

    Q_INVOKABLE void post(const QString& url, const QString& urlEncodedPostData = QString());
    Q_INVOKABLE void post(const QString& url, const QVariantMap& customHeaders, const QString& urlEncodedPostData = QString());

signals:
    void statusChanged();
    void errorChanged();
    void errorMessageChanged();
    void dataChanged();
    void urlChanged();
    void userAgentChanged();
    void networkAccessManagerChanged();
    void httpStatusCodeChanged();
    void finalUrlChanged();
    void headersChanged();

private slots:
    void requestFinished();


private: // methods
    void setUrl(const QString& value);
    void setData(const QString& value);
    void setStatus(Status value);
    void setError(Error value);
    void setErrorMessage(const QString& value);
    void setHttpStatusCode(int value);
    void setFinalUrl(const QString& value);
    QNetworkRequest makeRequest(const QUrl& url);
    void finish(Error error, const QString& errorMessage);

private: // member vars
    QNetworkAccessManager* m_NetworkAccessManager;
    QNetworkReply* m_Reply;
    Status m_Status;
    Error m_Error;
    int m_HttpStatusCode;
    QString m_Data;
    QString m_UserAgent;
    QString m_Url;
    QString m_ErrorMessage;
    QString m_FinalUrl;
    QVariantMap m_Headers;
    QVariantMap m_RequestHeaders;
    int m_Redirects;

private:
    static QString ms_UserAgent;
    static QNetworkAccessManager* ms_NetworkAccessManager;
    static QVariantMap ms_DefaultHeaders;
};



