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

#include "QuickHttp.h"

#include <QDebug>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QNetworkAccessManager>
#include <QUrlQuery>
#include "QuickCookieJar.h"

QString QuickHttp::ms_UserAgent;
QNetworkAccessManager* QuickHttp::ms_NetworkAccessManager;
QVariantMap QuickHttp::ms_DefaultHeaders;

namespace
{
const int MaxRedirects = 10;
}

QuickHttp::~QuickHttp()
{
    if (m_Reply) {
        m_Reply->abort(); // should be sync
    }
}

QuickHttp::QuickHttp(QObject* parent)
    : QObject(parent)
    , m_NetworkAccessManager(nullptr)
    , m_Reply(nullptr)
    , m_Status(StatusNone)
    , m_Error(ErrorNone)
    , m_HttpStatusCode(0)
    , m_Redirects(0)
{

}

void QuickHttp::get(const QString& url)
{
    get(url, QVariantMap());
}

void QuickHttp::get(const QString& url, const QVariantMap& requestHeaders)
{
    switch (m_Status) {
    case StatusRunning:
        qWarning() << "already running";
        return;
    default:
        break;
    }

    setUrl(url);
    setHttpStatusCode(-1);
    m_RequestHeaders = requestHeaders;
    m_Redirects = 0;

    if (m_Url.isEmpty()) {
        qWarning() << "empty url";
        finish(ErrorUrlEmpty, QString());
        return;
    }

    auto mgr = networkAccessManager();
    if (!mgr) {
        qWarning() << "network access manager not set";
        finish(ErrorRequestFailed, QString());
        return;
    }

    setError(ErrorNone);
    setErrorMessage(QString());
    setData(QString());
    setStatus(StatusRunning);
    m_Reply = mgr->get(makeRequest(QUrl(m_Url)));
    connect(m_Reply, &QNetworkReply::finished, this, &QuickHttp::requestFinished);
    qDebug() << "start download of" << m_Url;
}

void QuickHttp::setUrl(const QString& value)
{
    if (m_Url != value) {
        m_Url = value;
        emit urlChanged();
    }
}

QString QuickHttp::userAgent() const
{
    return m_UserAgent.isEmpty() ? ms_UserAgent : m_UserAgent;
}

void QuickHttp::setUserAgent(const QString& value)
{
    if (m_UserAgent != value) {
        m_UserAgent = value;
        emit userAgentChanged();
    }
}

void QuickHttp::setHeaders(const QVariantMap& value)
{
    if (m_Headers != value) {
        m_Headers = value;
        emit headersChanged();
    }
}

QNetworkAccessManager* QuickHttp::networkAccessManager() const
{
    return m_NetworkAccessManager ? m_NetworkAccessManager : ms_NetworkAccessManager;
}

void QuickHttp::setNetworkAccessManager(QNetworkAccessManager* value)
{
    if (m_NetworkAccessManager != value) {
        m_NetworkAccessManager = value;
        emit networkAccessManagerChanged();
    }
}

void QuickHttp::setData(const QString& value)
{
    if (m_Data != value) {
        m_Data = value;
        emit dataChanged();
    }
}

void QuickHttp::setStatus(Status value)
{
    if (m_Status != value) {
        m_Status = value;
        emit statusChanged();
    }
}

void QuickHttp::setError(Error value)
{
    if (m_Error != value) {
        m_Error = value;
        emit errorChanged();
    }
}

void QuickHttp::setHttpStatusCode(int value)
{
    if (m_HttpStatusCode != value) {
        m_HttpStatusCode = value;
        emit httpStatusCodeChanged();
    }
}

void QuickHttp::setFinalUrl(const QString& value)
{
    if (m_FinalUrl != value) {
        m_FinalUrl = value;
        emit finalUrlChanged();
    }
}

void QuickHttp::setErrorMessage(const QString& value)
{
    if (m_ErrorMessage != value) {
        m_ErrorMessage = value;
        emit errorMessageChanged();
    }
}

void QuickHttp::finish(Error error, const QString& errorMessage)
{
    setError(error);
    setErrorMessage(errorMessage);
    // status last: QML handlers react to it and read the rest
    setStatus(StatusCompleted);
}

void QuickHttp::requestFinished()
{
    Q_ASSERT(m_Reply);
    auto reply = m_Reply;
    m_Reply = nullptr;
    reply->deleteLater();

    int httpStatusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    setHttpStatusCode(httpStatusCode);
    setFinalUrl(reply->url().toString());

    switch (reply->error()) {
    case QNetworkReply::OperationCanceledError:
        finish(ErrorCanceled, QString());
        break;
    case QNetworkReply::NoError: {
        // Get the http status code
        if (httpStatusCode >= 200 && httpStatusCode < 300) { // success
            // Here we got the final reply
            setData(QString::fromUtf8(reply->readAll()));
            finish(ErrorNone, QString());
        } else if (httpStatusCode >= 300 && httpStatusCode < 400) { // redirection
            // Get the redirection url
            auto newUrl = reply->attribute(QNetworkRequest::RedirectionTargetAttribute).toUrl();
            // Because the redirection url can be relative,
            // we have to use the previous one to resolve it
            newUrl = reply->url().resolved(newUrl);
            auto mgr = networkAccessManager();
            Q_ASSERT(mgr);
            if (!mgr || newUrl.isEmpty()) {
                finish(ErrorRequestFailed, reply->errorString());
            } else if (++m_Redirects > MaxRedirects) {
                qDebug() << "too many redirections";
                finish(ErrorRequestFailed, tr("Too many redirections"));
            } else {
                m_Reply = mgr->get(makeRequest(newUrl));
                connect(m_Reply, &QNetworkReply::finished, this, &QuickHttp::requestFinished);
            }
        } else  {
            qDebug() << "http status code:" << httpStatusCode;
            setData(QString::fromUtf8(reply->readAll()));
            finish(ErrorRequestFailed, reply->errorString());
        }
    } break;
    default: {
        qDebug() << "request failed: " << httpStatusCode << reply->errorString() << reply->url();
        // the body of an error page can tell why (blocked, removed, ...)
        setData(QString::fromUtf8(reply->readAll()));
        finish(ErrorRequestFailed, reply->errorString());
    } break;
    }
}

QNetworkRequest QuickHttp::makeRequest(const QUrl& url)
{
    QNetworkRequest request;
    request.setUrl(url);
    request.setRawHeader("User-Agent", userAgent().toUtf8()); // must be set else no reply

    const QVariantMap* maps[] = { &ms_DefaultHeaders, &m_Headers, &m_RequestHeaders };
    for (const auto* map : maps) {
        for (auto it = map->cbegin(); it != map->cend(); ++it) {
            request.setRawHeader(it.key().toUtf8(), it.value().toString().toUtf8());
        }
    }

    return request;
}

void QuickHttp::post(const QString& url, const QString& urlEncodedPostData)
{
    post(url, QVariantMap(), urlEncodedPostData);
}

void QuickHttp::post(const QString& url, const QVariantMap& customHeaders, const QString& urlEncodedPostData)
{
    switch (m_Status) {
    case StatusRunning:
        qWarning() << "already running";
        return;
    default:
        break;
    }

    setUrl(url);
    setHttpStatusCode(-1);
    m_RequestHeaders = customHeaders;
    m_Redirects = 0;

    if (m_Url.isEmpty()) {
        qWarning() << "empty url";
        finish(ErrorUrlEmpty, QString());
        return;
    }

    auto mgr = networkAccessManager();
    if (!mgr) {
        qWarning() << "network access manager not set";
        finish(ErrorRequestFailed, QString());
        return;
    }

    setError(ErrorNone);
    setErrorMessage(QString());
    setData(QString());
    setStatus(StatusRunning);

    // custom headers
    auto req = makeRequest(QUrl(m_Url));

    if (urlEncodedPostData.isEmpty()) {
        req.setHeader(QNetworkRequest::ContentLengthHeader, 0);
        m_Reply = mgr->sendCustomRequest(req, "POST");
    } else {
        req.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded; charset=UTF-8");
        m_Reply = mgr->post(req, urlEncodedPostData.toUtf8());
    }
    connect(m_Reply, &QNetworkReply::finished, this, &QuickHttp::requestFinished);
}
