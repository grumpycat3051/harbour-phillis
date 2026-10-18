#!/bin/sh
# Checks that qml/Scraper.js gives the same results in Qt's JavaScript engine (qmlscene) as in
# Node, on the fixtures. Needs qmlscene (Qt 5) and node.
cd "$(dirname "$0")" || exit 1
QT_SELECT=qt5 QML_XHR_ALLOW_FILE_READ=1 QT_QPA_PLATFORM=offscreen qmlscene qml/ScraperDump.qml 2>&1 \
    | sed -n 's/.*RESULT /RESULT /p' > /tmp/scraper-qt.txt
node dump-node.js > /tmp/scraper-node.txt
if [ ! -s /tmp/scraper-qt.txt ]; then
    echo "qmlscene printed nothing"
    exit 1
fi
if diff /tmp/scraper-qt.txt /tmp/scraper-node.txt > /tmp/scraper-diff.txt; then
    echo "Qt and Node agree on $(wc -l < /tmp/scraper-qt.txt) results"
else
    echo "Qt and Node differ:"
    head -c 3000 /tmp/scraper-diff.txt
    exit 1
fi
