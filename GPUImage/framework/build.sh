#!/bin/bash

set -e

IOSSDK_VER="9.3"


# xcodebuild -showsdks

xcodebuild -workspace GPUImage.xcworkspace -scheme GPUImage -configuration Release -sdk iphoneos${IOSSDK_VER} build

xcodebuild -workspace GPUImage.xcworkspace -scheme GPUImage -configuration Release -sdk iphonesimulator${IOSSDK_VER} build

# change to build file
cd Build/Products


# for the fat lib file
mkdir -p Release-iphone/lib
xcrun -sdk iphoneos lipo -create Release-iphoneos/libGPUImage.a Release-iphonesimulator/libGPUImage.a -output Release-iphone/lib/libGPUImage.a
xcrun -sdk iphoneos lipo -create Release-iphoneos/libPods.a Release-iphonesimulator/libPods.a -output Release-iphone/lib/libPods.a
xcrun -sdk iphoneos lipo -create Release-iphoneos/libUriParser-cpp.a Release-iphonesimulator/libUriParser-cpp.a -output Release-iphone/lib/libUriParser-cpp.a
xcrun -sdk iphoneos lipo -create Release-iphoneos/libVideoCore.a Release-iphonesimulator/libVideoCore.a -output Release-iphone/lib/libVideoCore.a
xcrun -sdk iphoneos lipo -info Release-iphone/lib/libGPUImage.a
# for header files
mkdir -p Release-iphone/include
cp ../../Source/GPUImageApi.h Release-iphone/include



# cp to IOSStreamers
cp -rf Release-iphone/lib    ../../../../IOSStreamers/IOSStreamer/
cp -rf Release-iphone/include ../../../../IOSStreamers/IOSStreamer/

cd ../../../../IOSStreamers

xcodebuild -project IOSStreamer.xcodeproj -target IOSStreamer -configuration Release -sdk iphoneos${IOSSDK_VER} build
xcodebuild -project IOSStreamer.xcodeproj -target IOSStreamer -configuration Release -sdk iphonesimulator${IOSSDK_VER} build



