#!/bin/bash
# 编译 + 打包 OπTXT.app（纯 SwiftUI，不依赖 .NET）
set -e
cd "$(dirname "$0")"

APP="dist/OπTXT.app"
rm -rf build "$APP"
mkdir -p build "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "==> 编译"
swiftc -O -o build/OpiTXT Sources/*.swift

echo "==> 图标：唯一母版 Packaging/AppIcon.png，现场生成 icon.icns（访达 / Dock / 切换器 / 关于 / 引导页全部同源）"
ICONSET=build/AppIcon.iconset
rm -rf "$ICONSET"; mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
  sips -z $s $s Packaging/AppIcon.png --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) Packaging/AppIcon.png --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/icon.icns"
cp "$APP/Contents/Resources/icon.icns" Packaging/icon.icns
cp Packaging/AppIcon.png "$APP/Contents/Resources/AppIcon.png"

echo "==> 组装"
cp build/OpiTXT "$APP/Contents/MacOS/OpiTXT"
cp Packaging/Info.plist "$APP/Contents/Info.plist"
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

echo "==> 刷新系统图标缓存（不然访达会显示成灰色 / 蓝色网格占位）"
touch "$APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP" >/dev/null 2>&1 || true
rm -rf /var/folders/rh/w7g2bh3j33z214lpl3f79r1m0000gn/C/com.apple.iconservices* 2>/dev/null || true
killall Finder >/dev/null 2>&1 || true
killall Dock >/dev/null 2>&1 || true

echo "完成：$APP"
