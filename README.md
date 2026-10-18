# harbour-phillis
PHillis is an unofficial Sailfish OS client for the adult content website [Pornhub](https://www.pornhub.com/).

Binaries for your device are available on [OpenRepos](https://openrepos.net/content/grumpycat3051/phillis).

## This fork

Version 0.5.0 updates the app for the website as it is in 2026:

- Pages are read by `qml/Scraper.js`, which looks up each value on its own (by attribute or
  class name, with fallbacks for older markup), so a small change on the site no longer
  breaks a whole list. `tests/` has example pages and tests for it:
  `node tests/scraper.test.js`, and `tests/compare-engines.sh` runs the same code in Qt's
  JavaScript engine.
- Login fetches the current login form and sends its fields with your account.
- Videos play with the Referer and Origin headers the site's video servers now ask for.
- The app identifies as a desktop browser, so it gets the same pages a browser does.
- Settings > pull-down menu > *Check the website* loads the pages the app reads and reports
  what it found (counts, status codes and the page structure, without titles or names).
  Copy the report from its pull-down menu when something doesn't work.

Each push builds an armv7hl RPM for Sailfish OS 5.1.0.11 on GitHub Actions (see the
*Actions* tab; the RPM is in the run's artifacts). Run the workflow by hand to build for
another release or for aarch64.
