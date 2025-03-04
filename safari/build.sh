#!/bin/sh
#exit on errors
set -e
source ./env
cat <<EOF | envsubst > ./ExportOptions.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>signingCertificate</key>
    <string>Apple Distribution</string>
    <key>uploadBitcode</key>
    <true/>
    <key>uploadSymbols</key>
    <true/>
    <key>provisioningProfiles</key>
    <dict>
        <key>$BUNDLE_ID</key>
        <string>XC org senns AboveVTT</string>
        <key>$BUNDLE_ID.Extension</key>
        <string>XC org senns AboveVTT Extension</string>
    </dict>
</dict>
</plist>
EOF


echo "Clean"
rm -r build/*.pkg build/*.ipa build/*.xcarchive build/*.log build/*.plist

xcodebuild clean -project AboveVTT.xcodeproj -scheme "AboveVTT (iOS)" -destination 'generic/platform=iOS' -configuration Release
xcodebuild clean -project AboveVTT.xcodeproj -scheme "AboveVTT (macOS)" -destination 'generic/platform=macOS' -configuration Release

echo "Building iOS"
xcodebuild build -project AboveVTT.xcodeproj -scheme "AboveVTT (iOS)" -destination 'generic/platform=iOS' -configuration Release
xcodebuild archive -project AboveVTT.xcodeproj -scheme "AboveVTT (iOS)" -archivePath ./build/AboveVTT-ios.xcarchive -destination 'generic/platform=iOS' -configuration Release 

echo "Building macOS"
xcodebuild build -project AboveVTT.xcodeproj -scheme "AboveVTT (macOS)" -destination 'generic/platform=macOS' -configuration Release
xcodebuild archive -project AboveVTT.xcodeproj -scheme "AboveVTT (macOS)" -archivePath ./build/AboveVTT-mac.xcarchive -destination 'generic/platform=macOS' -configuration Release

echo "DEBUG: Check what signing"
security find-identity -v -p codesigning
echo "Export plist:"
cat ExportOptions.plist

echo "Export iOS"
xcodebuild -exportArchive -archivePath ./build/AboveVTT-ios.xcarchive -exportPath ./build -exportOptionsPlist ExportOptions.plist -verbose

echo "Export macOS"
xcodebuild -exportArchive -archivePath ./build/AboveVTT-mac.xcarchive -exportPath ./build -exportOptionsPlist ExportOptions.plist -verbose

echo "Notarizing iOS"
xcrun notarytool submit ./build/AboveVTT.ipa --keychain-profile "appstoreconnect" --wait

echo "Notarizing macOS"
xcrun notarytool submit ./build/AboveVTT.pkg --keychain-profile "appstoreconnect" --wait


echo "Uploading iOS"
#skip for test: xcrun altool --upload-app -f ./build/AboveVTT.ipa -t ios --apiKey $APP_STORE_CONNECT_API_KEY_ID --apiIssuer $APP_STORE_CONNECT_API_ISSUER_ID

echo "Uploading macOS"
#skip for test: xcrun altool --upload-app -f ./build/AboveVTT.pkg -t macos --apiKey $APP_STORE_CONNECT_API_KEY_ID --apiIssuer $APP_STORE_CONNECT_API_ISSUER_ID

echo "Completed"


