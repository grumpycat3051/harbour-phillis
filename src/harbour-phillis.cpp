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

#include <QtQuick>

#include <QNetworkAccessManager>

#include <sailfishapp.h>

#include "QuickHttp.h"
#include "QuickDownloadCache.h"
#include "QuickApp.h"
#include "QuickCookieJar.h"




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
    qmlRegisterSingletonType<QuickDownloadCache>(PHILLIS_NAMESPACE, 1, 0, "DownloadCache", downloadCacheProvider);
    qmlRegisterSingletonType<QuickApp>(PHILLIS_NAMESPACE, 1, 0, "App", appProvider);
    qmlRegisterUncreatableType<QNetworkAccessManager>(PHILLIS_NAMESPACE, 1, 0, "NAM", QStringLiteral("QML warnings"));
    qmlRegisterUncreatableType<QuickCookieJar>(PHILLIS_NAMESPACE, 1, 0, "CookieJar", QStringLiteral("QML warnings"));

    QNetworkAccessManager nam;
    QuickHttp::SetNetworkAccessManager(&nam);
    //QuickHttp::SetUserAgent("Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/60.0");
    QuickHttp::SetUserAgent(QStringLiteral("PHillis " QT_STRINGIFY(PHILLIS_VERSION_MAJOR) "." QT_STRINGIFY(PHILLIS_VERSION_MINOR)));
    QuickCookieJar cookieJar;
    nam.setCookieJar(&cookieJar);
    // clear owner, else QNetworkAccessManager will delete
    cookieJar.setParent(nullptr);


    int result = 0;
    {
        QScopedPointer<QQuickView> view(SailfishApp::createView());

        view->engine()->rootContext()->setContextProperty("cookieJar", &cookieJar);

        QQmlComponent keepAlive(view->engine());
        keepAlive.setData(
"import QtQuick 2.0\n"
"import Nemo.KeepAlive 1.1\n"
"Item {\n"
"   property bool preventBlanking: false\n"
"   onPreventBlankingChanged: DisplayBlanking.preventBlanking = preventBlanking\n"
"}\n",
                    QString());
        QScopedPointer<QQuickItem> item(qobject_cast<QQuickItem*>(keepAlive.create()));
        if (item) {
            view->engine()->rootContext()->setContextProperty("KeepAlive", item.data());
        }

        switch (keepAlive.status()) {
        case QQmlComponent::Ready:
            qInfo("Using Nemo.KeepAlive 1.1 DisplayBlanking.\n");
            break;
        default:
            qInfo("Nemo.KeepAlive 1.1 DisplayBlanking not available.\n");
            qDebug() << keepAlive.errors();
            break;
        }

        view->setSource(SailfishApp::pathToMainQml());
        view->requestActivate();
        view->show();
        result = app->exec();
    }
//    QObject::connect(app.data(), &QCoreApplication::aboutToQuit, [&] {
//        auto item = view->rootObject();
//        if (item) {
//            QMetaObject::invokeMethod(item, "aboutToQuit");
//        }
//    });
    return result;
}

