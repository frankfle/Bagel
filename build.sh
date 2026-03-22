#!/bin/bash

case "$1" in
  mac)
    xcodebuild -workspace mac/Bagel.xcworkspace -scheme Bagel clean
    xcodebuild -workspace mac/Bagel.xcworkspace -scheme Bagel build
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
    echo "Usage: $0 {mac|library|test}"
    exit 1
    ;;
esac
