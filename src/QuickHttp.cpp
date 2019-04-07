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
{

}

void QuickHttp::get(const QString& url)
{
    switch (m_Status) {
    case StatusRunning:
        qWarning() << "already running";
        return;
    default:
        break;
    }

    setUrl(url);

    if (m_Url.isEmpty()) {
        qWarning() << "empty url";
        setError(ErrorUrlEmpty);
        setStatus(StatusCompleted);
        return;
    }

    auto mgr = networkAccessManager();
    if (!mgr) {
        qWarning() << "network access manager not set";
        setError(ErrorRequestFailed);
        setStatus(StatusCompleted);
        return;
    }

    setError(ErrorNone);
    setErrorMessage(QString());
    setStatus(StatusRunning);
    m_Reply = mgr->get(makeRequest(m_Url));
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

void QuickHttp::setErrorMessage(const QString& value)
{
    if (m_ErrorMessage != value) {
        m_ErrorMessage = value;
        emit errorMessageChanged();
    }
}

void QuickHttp::requestFinished()
{
    Q_ASSERT(m_Reply);
    auto reply = m_Reply;
    m_Reply = nullptr;
    reply->deleteLater();

    switch (reply->error()) {
    case QNetworkReply::OperationCanceledError:
        setError(ErrorCanceled);
        setStatus(StatusCompleted);
        break;
    case QNetworkReply::NoError: {
        // Get the http status code
        int v = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        if (v >= 200 && v < 300) { // success
            // Here we got the final reply
            setData(QString::fromUtf8(reply->readAll()));
            setStatus(StatusCompleted);
        } else if (v >= 300 && v < 400) { // redirection
            // Get the redirection url
            auto newUrl = reply->attribute(QNetworkRequest::RedirectionTargetAttribute).toUrl();
            // Because the redirection url can be relative,
            // we have to use the previous one to resolve it
            newUrl = reply->url().resolved(newUrl);
            auto mgr = networkAccessManager();
            Q_ASSERT(mgr);
            if (mgr) {
                m_Reply = mgr->get(makeRequest(newUrl));
                connect(m_Reply, &QNetworkReply::finished, this, &QuickHttp::requestFinished);
            } else {
                setError(ErrorRequestFailed);
                setStatus(StatusCompleted);
            }
        } else  {
            qDebug() << "http status code:" << v;
            setError(ErrorRequestFailed);
            setErrorMessage(reply->errorString());
            setStatus(StatusCompleted);
        }
    } break;
    default: {
        qDebug() << "request failed: " << reply->errorString() << reply->url();
        setError(ErrorRequestFailed);
        setErrorMessage(reply->errorString());
        setStatus(StatusCompleted);
    } break;
    }
}

QNetworkRequest QuickHttp::makeRequest(const QUrl& url)
{
    QNetworkRequest request;
    request.setUrl(url);
    request.setRawHeader("User-Agent", userAgent().toUtf8()); // must be set else no reply

    return request;
}

//void QuickHttp::login(const QString& username, const QString& password, const QString& redirect, const QString& token)
//{
//    QUrlQuery postData;
//    postData.addQueryItem("username", username);
//    postData.addQueryItem("password", password);
//    postData.addQueryItem("remember_me", "1");
//    postData.addQueryItem("token", token);
//    postData.addQueryItem("redirect", redirect);

//    setUrl(QStringLiteral("https://www.pornhub.com/front/authenticate"));

//    auto req = makeRequest(m_Url);
//    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");


//    setError(ErrorNone);
//    setErrorMessage(QString());
//    setStatus(StatusRunning);
//    m_Reply = networkAccessManager()->post(req, postData.toString(QUrl::FullyEncoded).toUtf8());
//    connect(m_Reply, &QNetworkReply::finished, this, &QuickHttp::requestFinished);
//}

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

    if (m_Url.isEmpty()) {
        qWarning() << "empty url";
        setError(ErrorUrlEmpty);
        setStatus(StatusCompleted);
        return;
    }

    auto mgr = networkAccessManager();
    if (!mgr) {
        qWarning() << "network access manager not set";
        setError(ErrorRequestFailed);
        setStatus(StatusCompleted);
        return;
    }

    setError(ErrorNone);
    setErrorMessage(QString());
    setStatus(StatusRunning);


    auto req = makeRequest(m_Url);

    // custom headers
    const auto beg = customHeaders.cbegin();
    const auto end = customHeaders.cend();
    for (auto it = beg; it != end; ++it) {
        req.setRawHeader(it.key().toUtf8(), it.value().toString().toUtf8());
    }


    if (urlEncodedPostData.isEmpty()) {
        req.setHeader(QNetworkRequest::ContentLengthHeader, 0);
        m_Reply = networkAccessManager()->sendCustomRequest(req, "POST");
    } else {
        req.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded; charset=UTF-8");
        m_Reply = networkAccessManager()->post(req, urlEncodedPostData.toUtf8());
    }
    connect(m_Reply, &QNetworkReply::finished, this, &QuickHttp::requestFinished);
}
