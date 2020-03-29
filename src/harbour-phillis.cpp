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

#include <QtQuick>

#include <QNetworkAccessManager>
#include <QSettings>

#include <sailfishapp.h>

#include "QuickHttp.h"
#include "QuickDownloadCache.h"
#include "QuickApp.h"
#include "QuickCookieJar.h"
#include "QuickConfigurationValue.h"
#include "QuickProxy.h"



static QObject *downloadCacheProvider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    return new QuickDownloadCache();
}

static QObject *appProvider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    return new QuickApp();
}

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    qmlRegisterType<QuickHttp>(PHILLIS_NAMESPACE, 1, 0, "Http");
    qmlRegisterType<QuickConfigurationValue>(PHILLIS_NAMESPACE, 1, 0, "ConfigurationValue");
    qmlRegisterType<QuickProxy>(PHILLIS_NAMESPACE, 1, 0, "Proxy");
    qmlRegisterSingletonType<QuickDownloadCache>(PHILLIS_NAMESPACE, 1, 0, "DownloadCache", downloadCacheProvider);
    qmlRegisterSingletonType<QuickApp>(PHILLIS_NAMESPACE, 1, 0, "App", appProvider);
    qmlRegisterUncreatableType<QNetworkAccessManager>(PHILLIS_NAMESPACE, 1, 0, "NAM", QStringLiteral("QML warnings"));
    qmlRegisterUncreatableType<QuickCookieJar>(PHILLIS_NAMESPACE, 1, 0, "CookieJar", QStringLiteral("QML warnings"));

    QNetworkAccessManager nam;
    QSettings settings;

    QuickHttp::SetNetworkAccessManager(&nam);
//    QuickHttp::SetUserAgent("Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:69.0) Gecko/20100101 Firefox/69.0");
    QuickHttp::SetUserAgent(QStringLiteral("PHillis " QT_STRINGIFY(PHILLIS_VERSION_MAJOR) "." QT_STRINGIFY(PHILLIS_VERSION_MINOR)));
    QuickCookieJar cookieJar;
    nam.setCookieJar(&cookieJar);
    // clear owner, else QNetworkAccessManager will delete
    cookieJar.setParent(nullptr);

    QuickConfigurationValue::SetSettings(&settings);
    QuickApp::SetSettings(&settings);


    int result = 0;
    {
        QScopedPointer<QQuickView> view(SailfishApp::createView());
        view->engine()->rootContext()->setContextProperty("cookieJar", &cookieJar);
        view->setSource(SailfishApp::pathToMainQml());
        view->requestActivate();
        view->show();
        result = app->exec();
    }

    return result;
}

