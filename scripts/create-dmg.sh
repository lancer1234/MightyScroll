#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
output_dir="${1:-$project_root/build}"
mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"
package_dir="$(mktemp -d "${TMPDIR:-/tmp/}mightyscroll-package.XXXXXX")"
trap 'rm -rf "$package_dir"' EXIT

xcodebuild -project "$project_root/MightyScroll.xcodeproj" \
  -scheme MightyScroll -configuration Release \
  -derivedDataPath "$package_dir/DerivedData" \
  ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO build

app_path="$package_dir/DerivedData/Build/Products/Release/MightyScroll.app"
version="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app_path/Contents/Info.plist")"
codesign --verify --deep --strict "$app_path"
architectures="$(lipo -archs "$app_path/Contents/MacOS/MightyScroll")"
for architecture in arm64 x86_64; do
  case " $architectures " in
    *" $architecture "*) ;;
    *) echo "Missing architecture: $architecture" >&2; exit 1 ;;
  esac
done
mkdir "$package_dir/Image"
ditto "$app_path" "$package_dir/Image/MightyScroll.app"
ln -s /Applications "$package_dir/Image/Applications"
cp "$project_root/LICENSE" "$package_dir/Image/LICENSE.txt"
cp "$project_root/docs/INSTALL.txt" "$package_dir/Image/INSTALL.txt"
hdiutil create -volname "MightyScroll" -srcfolder "$package_dir/Image" \
  -format UDZO -ov "$output_dir/MightyScroll-$version-universal.dmg"
hdiutil verify "$output_dir/MightyScroll-$version-universal.dmg"
(cd "$output_dir" && shasum -a 256 "MightyScroll-$version-universal.dmg" > SHA256SUMS.txt)
