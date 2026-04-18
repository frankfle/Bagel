#!/bin/bash

case "$1" in
  mac)
    xcodebuild -workspace mac/Bagel.xcworkspace -scheme Bagel clean
    xcodebuild -workspace mac/Bagel.xcworkspace -scheme Bagel build
    ;;
  dmg)
    ./build-dmg.sh
    ;;
  dist)
    ARCHIVE_PATH=/tmp/Bagel.xcarchive
    EXPORT_PATH="$(pwd)/dist"
    rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"
    xcodebuild -workspace mac/Bagel.xcworkspace -scheme Bagel -configuration Release clean archive -archivePath "$ARCHIVE_PATH"
    xcodebuild -exportArchive -archivePath "$ARCHIVE_PATH" -exportPath "$EXPORT_PATH" -exportOptionsPlist mac/ExportOptions.plist
    echo "App exported to $EXPORT_PATH/Bagel.app"
    ;;
  library)
    xcodebuild -project iOS/Bagel.xcodeproj -scheme Bagel -destination 'generic/platform=iOS Simulator' clean
    xcodebuild -project iOS/Bagel.xcodeproj -scheme Bagel -destination 'generic/platform=iOS Simulator' build
    ;;
  test)
    xcodebuild -project test/test.xcodeproj -scheme test -destination 'generic/platform=iOS Simulator' clean
    xcodebuild -project test/test.xcodeproj -scheme test -destination 'generic/platform=iOS Simulator' build
    ;;
  *)
    echo "Usage: $0 {mac|dmg|dist|library|test}"
    exit 1
    ;;
esac
