TARGET = harbour-phillis

# known to qmake
VER_MAJ = 0
VER_MIN = 2
VER_PAT = 3

VERSION = $${VER_MAJ}.$${VER_MIN}.$${VER_PAT}

PHILLIS_NAMESPACE=grumpycat
DEFINES += PHILLIS_APP_NAME=\"\\\"\"harbour-phillis\"\\\"\"
DEFINES += PHILLIS_VERSION_MAJOR=$$VER_MAJ
DEFINES += PHILLIS_VERSION_MINOR=$$VER_MIN
DEFINES += PHILLIS_VERSION_PATCH=$$VER_PAT
DEFINES += PHILLIS_NAMESPACE=\"\\\"\"$$PHILLIS_NAMESPACE\"\\\"\"
DEFINES += PHILLIS_DATADIR="/usr/share/$${TARGET}"



CONFIG += sailfishapp


HEADERS += \
    src/QuickCookieJar.h \
    src/QuickHttp.h \
    src/QuickConfigurationValue.h
HEADERS += src/QuickDownloadCache.h
HEADERS += src/QuickApp.h


SOURCES += src/harbour-phillis.cpp \
    src/QuickCookieJar.cpp \
    src/QuickHttp.cpp \
    src/QuickConfigurationValue.cpp
SOURCES +=
SOURCES += src/QuickDownloadCache.cpp
SOURCES += src/QuickApp.cpp



DISTFILES += \
    rpm/harbour-phillis.changes.in \
    rpm/harbour-phillis.changes.run.in \
    rpm/harbour-phillis.spec \
    rpm/harbour-phillis.yaml \
    media/*.png \
    harbour-phillis.desktop \
    qml/Constants.qml \
    qml/harbour-phillis.qml \
    qml/qmldir \
    qml/cover/CoverPage.qml \
    qml/TopMenu.qml \
    qml/FramedImage.qml \
    qml/FormatComboBox.qml \
    qml/pages/StartPage.qml \
    qml/pages/CategoriesPage.qml \
    qml/pages/VideosPage.qml \
    qml/pages/AboutPage.qml \
    qml/pages/SettingsPage.qml \
    qml/pages/VideoPlayerPage.qml \
    qml/pages/NavigationItem.qml \
    qml/pages/PornstarsPage.qml \
    qml/pages/AdultContentDisclaimerPage.qml \
    qml/pages/LockScreenPage.qml




SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG lines
CONFIG += sailfishapp_i18n
CONFIG += sailfishapp_i18n_idbased
CONFIG += sailfishapp_i18n_unfinished

# To specify additional translation sources, add:
TRANSLATION_SOURCES += $$PWD/qml
TRANSLATION_SOURCES += $$PWD/src

TRANSLATIONS += translations/harbour-phillis.ts
TRANSLATIONS += translations/harbour-phillis-zh_CN.ts

DISTFILES += $$TRANSLATIONS


media.path = /usr/share/$${TARGET}/media
media.files += media/*.png
INSTALLS += media



