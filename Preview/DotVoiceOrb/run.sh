#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
output="${1:-/tmp/DotVoiceOrbDemo.app}"
mkdir -p "$output/Contents/MacOS" "$output/Contents/Frameworks"
sdk="$output/Contents/Frameworks"
swiftc -emit-library -emit-module -module-name DockDoorWidgetSDK -emit-module-path "$sdk/DockDoorWidgetSDK.swiftmodule" Sources/DockDoorWidgetSDK/*.swift -o "$sdk/libDockDoorWidgetSDK.dylib"
install_name_tool -id @rpath/libDockDoorWidgetSDK.dylib "$sdk/libDockDoorWidgetSDK.dylib"
swiftc -parse-as-library -I "$sdk" -L "$sdk" -lDockDoorWidgetSDK -Xlinker -rpath -Xlinker @executable_path/../Frameworks Widgets/DotGlass/DotTheme.swift Widgets/DotGlass/DotVoiceOrb.swift Preview/DotVoiceOrb/Demo.swift -o "$output/Contents/MacOS/DotVoiceOrbDemo"
cat > "$output/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?><plist version="1.0"><dict><key>CFBundleIdentifier</key><string>local.dotglass.voiceorb.demo</string><key>CFBundleExecutable</key><string>DotVoiceOrbDemo</string><key>CFBundleName</key><string>Dot Voice Orb Demo</string><key>CFBundlePackageType</key><string>APPL</string><key>NSHighResolutionCapable</key><true/></dict></plist>
PLIST
xattr -cr "$output"
codesign --force --deep --sign - "$output"
open "$output"
