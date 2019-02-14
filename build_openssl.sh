#!/bin/bash
# Jonathan Cardasis - 2018
# Builds OpenSSL libssl and libcrypto for macOS
# binary distribution (i386 and x86).

VERSION="1.0.2q"

# 1.1.0j
VERSION_SHA256_CHECKSUM="5744cfcbcec2b1b48629f7354203bc1e5e9b5466998bbccc5b5fcde3b18eb684"
#VERSION_SHA256_CHECKSUM="31bec6c203ce1a8e93d5994f4ed304c63ccf07676118b6634edded12ad1b3246"
# 1.1.0g
#VERSION_SHA256_CHECKSUM="de4d501267da39310905cb6dc8c6121f7a2cad45a7707f76df828fe1b85073af"
# 1.1.1a
#VERSION_SHA256_CHECKSUM="fc20130f8b7cbd2fb918b2f14e2f429e109c31ddd0fb38fc5d71d9ffed3f9f41"
####################################
curl -O https://www.openssl.org/source/openssl-$VERSION.tar.gz

# Run a checksum to ensure this file wasn't tampered with
FILE_CHECKSUM=$(shasum -a 256 openssl-$VERSION.tar.gz | awk '{print $1; exit}')
if [ "$FILE_CHECKSUM" != "$VERSION_SHA256_CHECKSUM" ]; then
  echo "OpenSSL v$VERSION failed checksum. Please ensure that you are on a trusted network."
  exit 1
fi

OPENSSL_FOLDER="OpenSSL"

# Create openssl folder structure, hidden at first
mkdir ".$OPENSSL_FOLDER"
OPENSSL_LIB_FOLDER=".$OPENSSL_FOLDER/lib"
OPENSSL_INCLUDE_FOLDER=".$OPENSSL_FOLDER/include"
mkdir "$OPENSSL_LIB_FOLDER"

# Unzip into i386 and x86 64bit folders
tar -xvzf openssl-$VERSION.tar.gz
mv openssl-$VERSION openssl_i386
tar -xvzf openssl-$VERSION.tar.gz
mv openssl-$VERSION openssl_x86_64

# Build Flavors
#cd openssl_i386
#./Configure darwin-i386-cc
#echo "Building i386 static library..."
#make >> /dev/null 2>&1
#make install >> /dev/null 2>&1
#cd ../

cd openssl_x86_64
./Configure darwin64-x86_64-cc
echo "Building x86 64 static library..."
make >> /dev/null 2>&1
make install >> /dev/null 2>&1
cd ../

# Copy include and License into main OpenSSL folder (done after configure so <openssl/opensslconf.h> can be generated)
cd openssl_x86_64
cp -r include "../.$OPENSSL_FOLDER" # Copy include headers into hidden folder
cp LICENSE "../.$OPENSSL_FOLDER" # Copy License
cd ../

# Link
echo "Linking..."
lipo -create openssl_x86_64/libcrypto.a -output "$OPENSSL_LIB_FOLDER/libcrypto.a"
lipo -create openssl_x86_64/libssl.a -output "$OPENSSL_LIB_FOLDER/libssl.a"

# Cleanup
rm openssl-$VERSION.tar.gz
rm -r openssl_i386
rm -r openssl_x86_64
mv ".$OPENSSL_FOLDER" "$OPENSSL_FOLDER"

echo "Finished OpenSSL generation script."
