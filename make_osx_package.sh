#!/bin/sh -e

DIST=osx_package
VERSION=$(grep -e '^Version' pandoc.cabal | awk '{print $2}')
RESOURCES=$DIST/Resources
ROOT=$DIST/pandoc
SCRIPTS=osx-resources
BASE=pandoc-$VERSION
ME=jgm
CODESIGNID="Developer ID Application: Text Software Limited"

echo Removing old files...
rm -rf $DIST
mkdir -p $RESOURCES

echo Building pandoc...
cabal-dev install-deps
cabal-dev install --reinstall --force-reinstalls --flags="embed_data_files" citeproc-hs
cabal-dev configure --prefix=/usr/local --datasubdir=$BASE --docdir=/usr/local/doc/$BASE
cabal-dev build
cabal-dev copy --destdir=$ROOT
# remove library files
rm -r $ROOT/usr/local/lib
chown -R $ME:staff $DIST

gzip $ROOT/usr/local/share/man/man?/*.*
# cabal gives man pages the wrong permissions
chmod +r $ROOT/usr/local/share/man/man?/*.*

echo Copying license...
cp COPYING $RESOURCES/License.txt

PACKAGEMAKER=/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker

echo Creating OSX package...

sudo $PACKAGEMAKER \
    --root $ROOT \
    --id net.johnmacfarlane.pandoc \
    --resources $RESOURCES \
    --version $VERSION \
    --no-relocate \
    --scripts $SCRIPTS \
    --out $BASE.pkg

echo Signing package...

codesign --force --sign "$CODESIGNID" $BASE.pkg

echo Creating disk image...

sudo hdiutil create "$BASE.dmg" \
    -format UDZO -ov \
    -volname "pandoc $VERSION" \
    -srcfolder $BASE.pkg
sudo hdiutil internet-enable "$BASE.dmg"

