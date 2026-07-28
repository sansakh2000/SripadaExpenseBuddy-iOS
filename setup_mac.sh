#!/bin/bash
# Run this script on your Mac ONCE after cloning the repo.
# It installs XcodeGen and generates the Xcode project.

set -e

echo "==> Checking Xcode..."
xcode-select --print-path || { echo "Install Xcode from the App Store first!"; exit 1; }

echo "==> Installing Homebrew (if needed)..."
which brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "==> Installing XcodeGen..."
brew install xcodegen

echo "==> Generating Xcode project..."
cd "$(dirname "$0")"
xcodegen generate

echo ""
echo "✅ Done! Open SripadaExpenseBuddy.xcodeproj in Xcode."
echo "   Then:"
echo "   1. Select your Team in Signing & Capabilities"
echo "   2. Set your real device as the run destination"
echo "   3. Press ⌘R to build and run!"
