#!/bin/bash

ANDROID_DIR=$1
ANDROID_CLASS_DIR=`pwd`

if [ $# != 1 ]
then
echo "USAGE: setupanalysis.sh <PATH_TO_ANDROID_BUILD_ROOT_DIRECTORY>"
exit
fi

source ../bin/setup_env
echo Setting up analysis...

echo Getting relevant .class files...
../bin/getclasses.pl $ANDROID_DIR
../bin/extractjar.sh
rm -f *.jar
../bin/createclasslist.sh

echo Parsing AndroidManifest.xml files...
cd $ANDROID_DIR
find -name AndroidManifest.xml > manifestlist
$ANDROID_CLASS_DIR/../bin/parseandroidmanifest.pl > manifestpermission
grep ^contents:// manifestpermission | grep -v grantUriPermissions | sort -u > contentproviderpermission
sed -i 's/^contents/content/' contentproviderpermission
mv contentproviderpermission $ANDROID_CLASS_DIR
grep ^PROVIDER: manifestpermission | sort -u > providerauth
mv providerauth $ANDROID_CLASS_DIR
grep ^Intent: manifestpermission | sort -u > intentpermission
sed -i 's/^Intent://' intentpermission
mv intentpermission $ANDROID_CLASS_DIR
cd $ANDROID_CLASS_DIR

echo Generating 3rd party permission list...
../bin/parsepermission.pl $ANDROID_DIR/frameworks/base/core/res/AndroidManifest.xml > permissions

if [ ! -f ./com/android/internal/telephony/gsm/GSMPhone\$1.class ]
then
echo "Creating empty dummy GSMPhone\$1 class..."
../bin/compileemptyclass.pl com.android.internal.telephony.gsm.GSMPhone\$1
fi

if [ -f $ANDROID_DIR/frameworks/base/api/current.xml ]
then
echo Copying current.xml...
cp $ANDROID_DIR/frameworks/base/api/current.xml .
else
echo Copying current.txt...
cp $ANDROID_DIR/frameworks/base/api/current.txt .
fi

echo ""
echo "Please run the following line to test setup:"
echo "runsoot dump.DumpClass com.android.internal.telephony.gsm.GSMPhone"
echo "If no error, please run the following line to start analysis:"
echo "../bin/dumpclass.sh"
