#!/bin/bash

# Build script for JanusExample app
set -e  # Exit immediately if a command exits with a non-zero status

# Define colors for console output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📱 Building JanusExample app...${NC}"

# Define directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XCFRAMEWORK_PATH="$(dirname "$SCRIPT_DIR")/JanusSDK.xcframework"

# Verify XCFramework exists
if [ ! -d "$XCFRAMEWORK_PATH" ]; then
  echo "❌ JanusSDK.xcframework not found at $XCFRAMEWORK_PATH"
  echo "Please run '../../build_xcframework.sh' first to build the SDK"
  exit 1
fi

# Clean derived data for a fresh build
echo -e "${BLUE}🧹 Cleaning previous builds...${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/JanusExample-*

# Get available simulator
SIMULATOR_ID=$(xcrun simctl list devices available | grep "iPhone" | head -1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')

if [ -z "$SIMULATOR_ID" ]; then
  echo "❌ No available iPhone simulator found."
  exit 1
fi

echo -e "${BLUE}🔨 Building JanusExample for simulator...${NC}"

# Build the example app
xcodebuild build \
  -project JanusExample.xcodeproj \
  -scheme JanusExample \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -allowProvisioningUpdates

# Check if build was successful
if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ JanusExample build successful!${NC}"
  echo -e "${BLUE}🚀 You can now launch the app in the simulator with:${NC}"
  echo -e "xcrun simctl install $SIMULATOR_ID \$(find ~/Library/Developer/Xcode/DerivedData/JanusExample-* -name '*.app' | head -1)"
  echo -e "xcrun simctl launch $SIMULATOR_ID com.ethyca.JanusExample"
else
  echo "❌ Build failed"
  exit 1
fi 