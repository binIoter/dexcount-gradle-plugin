#!/usr/bin/env bash

set -e

# Not sure how well Travis deals with cwd; restore it on script exit.
DIR=`pwd`
trap "cd $DIR" SIGINT SIGTERM EXIT 

./gradlew clean check install

VERSION=`grep '^VERSION_NAME=' gradle.properties | cut -d '=' -f 2`

echo "Building integration test project..."
cd integration
./gradlew clean -PdexcountVersion="$VERSION" :app:assembleDebug > app.log
./gradlew clean -PdexcountVersion="$VERSION" :tests:assembleDebug > tests.log

echo "Integration build done!  Running tests..."

function die() {
  echo $1
  exit 1
}

grep -F 'Total methods in app-debug.apk: 16174 (24.68% used)' app.log || die "Incorrect method count in app-debug.apk"
grep -F 'Total fields in app-debug.apk:  7093 (10.82% used)' app.log || die "Incorrect field count in app-debug.apk"
grep -F 'Methods remaining in app-debug.apk: 49361' app.log || die "Incorrect remaining-method value in app-debug.apk"
grep -F 'Fields remaining in app-debug.apk:  58442' app.log || die "Incorrect remaining-field value in app-debug.apk"

grep -F 'Total methods in tests-debug.apk: 3065 (4.68% used)' tests.log || die "Incorrect method count in tests-debug.apk"
grep -F 'Total fields in tests-debug.apk:  771 (1.18% used)' tests.log || die "Incorrect field count in tests-debug.apk"
grep -F 'Methods remaining in tests-debug.apk: 62470' tests.log || die "Incorrect remaining-method value in tests-debug.apk"
grep -F 'Fields remaining in tests-debug.apk:  64764' tests.log || die "Incorrect remaining-field value in tests-debug.apk"

echo "Tests complete."
