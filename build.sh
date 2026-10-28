#!/bin/bash
# ============================================================================
#  QFMonitor — 独立网速悬浮窗 App 构建脚本
#
#  直接用 iOS SDK 的 clang 编译(不需要 Theos):
#    * 私有框架符号来自 libraries/*.tbd(上游 TrollSpeed, MIT)
#    * 打包成 .app, 用 ldid 带 entitlements 签名, 压成 1.ipa
# ============================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

APP_NAME="QFMonitor"
BUILD="$ROOT/build"
OUT_IPA="${1:-$ROOT/1.ipa}"
# 相对路径转绝对, 避免 cd 到 build/ 后写错位置
case "$OUT_IPA" in
  /*) ;;
  *) OUT_IPA="$ROOT/$OUT_IPA" ;;
esac

SDK_PATH="$(xcrun --sdk iphoneos --show-sdk-path)"
echo ">> SDK: $SDK_PATH"

rm -rf "$BUILD"
mkdir -p "$BUILD/FW"

# ---------------------------------------------------------------- 私有框架
# .tbd -> <Name>.framework/<Name> 形式, 供 -framework 解析
for fw in BackBoardServices GraphicsServices SpringBoardServices AssertionServices IOKit; do
  mkdir -p "$BUILD/FW/$fw.framework"
  cp "$ROOT/libraries/$fw.tbd" "$BUILD/FW/$fw.framework/$fw"
done

# IOKit 用的是完整符号 tbd, 但头文件仍从 SDK 拷一份过来(否则 #import <IOKit/...> 找不到)
mkdir -p "$BUILD/FW/IOKit.framework/Headers"
cp -R "$SDK_PATH/System/Library/Frameworks/IOKit.framework/Headers/." \
      "$BUILD/FW/IOKit.framework/Headers/" 2>/dev/null || true

# ---------------------------------------------------------------- 编译
SOURCES="$(ls "$ROOT"/src/*.m)"

xcrun -sdk iphoneos clang \
  -arch arm64 \
  -isysroot "$SDK_PATH" \
  -miphoneos-version-min=14.0 \
  -fobjc-arc \
  -O2 \
  -Wall \
  -Wno-unused-variable \
  -Wno-unused-function \
  -Wno-deprecated-declarations \
  -I"$ROOT/src" \
  -F"$BUILD/FW" \
  -framework BackBoardServices \
  -framework GraphicsServices \
  -framework SpringBoardServices \
  -framework AssertionServices \
  -framework IOKit \
  -framework UIKit \
  -framework Foundation \
  -framework CoreGraphics \
  -framework QuartzCore \
  -framework CoreFoundation \
  $SOURCES \
  -o "$BUILD/$APP_NAME"

echo ">> linked binary:"
file "$BUILD/$APP_NAME"

# ---------------------------------------------------------------- 打包 .app
APP_DIR="$BUILD/Payload/$APP_NAME.app"
mkdir -p "$APP_DIR"

cp "$BUILD/$APP_NAME" "$APP_DIR/$APP_NAME"
cp "$ROOT/Info.plist" "$APP_DIR/Info.plist"
plutil -convert xml1 "$APP_DIR/Info.plist"
chmod 755 "$APP_DIR/$APP_NAME"
chmod 644 "$APP_DIR/Info.plist"

# 图标(可选)
if [ -f "$ROOT/Resources/AppIcon60x60@2x.png" ]; then
  cp "$ROOT/Resources/AppIcon60x60@2x.png" "$APP_DIR/AppIcon60x60@2x.png"
fi

# ---------------------------------------------------------------- 签名
# TrollStore 会用 IPA 里的 entitlements 重新签, 这里用 ldid 写入 entitlements
ldid -S"$ROOT/ent.plist" "$APP_DIR/$APP_NAME"

echo ">> entitlements:"
codesign -d --entitlements - "$APP_DIR/$APP_NAME" 2>&1 | head -40 || true

# ---------------------------------------------------------------- 校验 Mach-O
echo ">> load commands:"
otool -L "$APP_DIR/$APP_NAME" | head -30

# ---------------------------------------------------------------- 打包 IPA
cd "$BUILD"
rm -f "$OUT_IPA"
zip -qr "$OUT_IPA" Payload
cd "$ROOT"

echo ">> OK: $OUT_IPA"
ls -la "$OUT_IPA"
