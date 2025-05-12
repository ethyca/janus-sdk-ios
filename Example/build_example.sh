#!/bin/bash

# Build script for JanusExample app
set -e  # Exit immediately if a command exits with a non-zero status

# Define colors for console output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}📱 Building JanusExample app...${NC}"

# Define directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XCFRAMEWORK_PATH="$(dirname "$SCRIPT_DIR")/JanusSDK.xcframework"
ZIP_PATH="$(dirname "$SCRIPT_DIR")/JanusSDK.xcframework.zip"

# Verify XCFramework exists or extract from zip
if [ ! -d "$XCFRAMEWORK_PATH" ]; then
  if [ -f "$ZIP_PATH" ]; then
    echo -e "${BLUE}🔄 JanusSDK.xcframework not found. Extracting from framework.zip...${NC}"
    unzip -o "$ZIP_PATH" -d "$(dirname "$SCRIPT_DIR")"
    
    if [ ! -d "$XCFRAMEWORK_PATH" ]; then
      echo -e "${RED}❌ Failed to extract JanusSDK.xcframework from zip file${NC}"
      exit 1
    else
      echo -e "${GREEN}✅ Successfully extracted JanusSDK.xcframework${NC}"
    fi
  else
    echo -e "${RED}❌ JanusSDK.xcframework not found at $XCFRAMEWORK_PATH${NC}"
    echo -e "${RED}❌ framework.zip not found at $ZIP_PATH${NC}"
    exit 1
  fi
fi

# Clean derived data for a fresh build
echo -e "${BLUE}🧹 Cleaning previous builds...${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/JanusExample-*

# Get available simulator
SIMULATOR_ID=$(xcrun simctl list devices available | grep "iPhone" | head -1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')

if [ -z "$SIMULATOR_ID" ]; then
  echo -e "${RED}❌ No available iPhone simulator found.${NC}"
  exit 1
fi

# Boot the simulator
echo -e "${BLUE}🚀 Booting simulator...${NC}"
xcrun simctl boot "$SIMULATOR_ID" || true  # Ignore error if already booted

# Open Simulator app to ensure UI is visible
echo -e "${BLUE}📱 Opening Simulator app...${NC}"
open -a Simulator

# Wait for simulator to finish booting
echo -e "${BLUE}⏳ Waiting for simulator to boot...${NC}"
sleep 3  # Give simulator time to boot

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
  APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/JanusExample-* -name '*.app' | head -1)
  
  echo -e "${GREEN}✅ JanusExample build successful!${NC}"
  echo -e "${BLUE}🚀 Installing and launching app in simulator...${NC}"
  
  # Install and launch the app
  xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"
  xcrun simctl launch "$SIMULATOR_ID" com.ethyca.janussdk.ios.example
  
  echo -e "${GREEN}✅ App installed and launched!${NC}"
else
  echo -e "${RED}❌ Build failed${NC}"
  exit 1
fi 