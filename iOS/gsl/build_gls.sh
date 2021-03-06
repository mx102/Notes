#!/bin/bash

PLATFORMPATH="/Applications/Xcode.app/Contents/Developer/Platforms"
TOOLSPATH="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin"
export IPHONEOS_DEPLOYMENT_TARGET="9.1"
pwd=`pwd`

findLatestSDKVersion()
{
sdks=`ls $PLATFORMPATH/$1.platform/Developer/SDKs`
arr=()
for sdk in $sdks
do
arr[${#arr[@]}]=$sdk
done

# Last item will be the current SDK, since it is alpha ordered
count=${#arr[@]}
if [ $count -gt 0 ]; then
sdk=${arr[$count-1]:${#1}}
num=`expr ${#sdk}-4`
SDKVERSION=${sdk:0:$num}
else
SDKVERSION="9.1"
fi
}

buildit()
{
target=$1
hosttarget=$1
platform=$2

if [[ $hosttarget == "x86_64" ]]; then
hostarget="i386"
elif [[ $hosttarget == "arm64" ]]; then
hosttarget="arm"
fi

export CC="$(xcrun -sdk iphoneos -find clang)"
export CPP="$CC -E"
export CFLAGS="-arch ${target} -isysroot $PLATFORMPATH/$platform.platform/Developer/SDKs/$platform$SDKVERSION.sdk -miphoneos-version-min=$IPHONEOS_DEPLOYMENT_TARGET -fembed-bitcode"
export AR=$(xcrun -sdk iphoneos -find ar)
export RANLIB=$(xcrun -sdk iphoneos -find ranlib)
export CPPFLAGS="-arch ${target}  -isysroot $PLATFORMPATH/$platform.platform/Developer/SDKs/$platform$SDKVERSION.sdk -miphoneos-version-min=$IPHONEOS_DEPLOYMENT_TARGET -fembed-bitcode"
export LDFLAGS="-arch ${target} -isysroot $PLATFORMPATH/$platform.platform/Developer/SDKs/$platform$SDKVERSION.sdk"

echo "BUILD target=$target hosttaget=$hosttarget platform=$platform"

mkdir -p $pwd/output/$target

./configure --prefix="$pwd/output/$target" --disable-shared --host=$hosttarget-apple-darwin

make clean > /dev/null
make -j 4
make install 
}

findLatestSDKVersion iPhoneOS

buildit armv7 iPhoneOS
buildit armv7s iPhoneOS
buildit arm64 iPhoneOS
buildit i386 iPhoneSimulator
buildit x86_64 iPhoneSimulator

LIPO=$(xcrun -sdk iphoneos -find lipo)
$LIPO -create $pwd/output/armv7/lib/libgslcblas.a  $pwd/output/armv7s/lib/libgslcblas.a $pwd/output/arm64/lib/libgslcblas.a $pwd/output/x86_64/lib/libgslcblas.a $pwd/output/i386/lib/libgslcblas.a -output libgslcblas.a

$LIPO -create $pwd/output/armv7/lib/libgsl.a  $pwd/output/armv7s/lib/libgsl.a $pwd/output/arm64/lib/libgsl.a $pwd/output/x86_64/lib/libgsl.a $pwd/output/i386/lib/libgsl.a -output libgsl.a

