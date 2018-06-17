------------------------------------------------------------
Preparation
------------------------------------------------------------
tar -xvzf PScout.tar.gz in <PScout_DIR>
source bin/setup_env

Install XML::Simple (if not installed already)
sudo perl -MCPAN -e shell
install XML::Simple

PScout directory contents:
<PScout_DIR>/bin - various scripts used in the analysis
<PScout_DIR>/soot - soot analysis programs of java class files

<PScout_DIR>/results
- <android_version>_allmappings: API calls (both documented and undocumented) to permission mapping
- <android_version>_publishedapimapping: documented API calls to permission mapping
- <android_version>_intentpermissions: intents with permission
- <android_version>_contentproviderpermission: content provider (URI string "content://") with permission
- <android_version>_contentproviderfieldpermission: content provider (URI field) with permission

------------------------------------------------------------
How to Run PScout:
------------------------------------------------------------
mkdir <ANDROID_CLASS_DIR>		# create new directory under <PScout_DIR>
cd <ANDROID_CLASS_DIR>
../bin/setupanalysis.sh <ANDROID_DIR>	# <ANDROID_DIR> is the root directory of the Android source code (should be already complied with lunch full-eng)
					# performs steps 1-3 described in the following "Detailed Analysis Steps Section"
testsetup				# step 4 (a few seconds)
../bin/dumpclass.sh			# step 5 (~half a day)
../bin/postprocess_1.sh 		# steps 6-11 (a few minutes)
../bin/intentpermissioncheck.sh		# step 12 (~half a day)
../bin/postprocess_2.sh			# step 12-16 (a few minutes)

------------------------------------------------------------
Detailed Analysis Step Descriptions
------------------------------------------------------------
1: Get the relevant class files from the android build <ANDROID_DIR> root directory

Put all classes in a new directory <ANDROID_CLASS_DIR> under <PScout_DIR>
../bin/getclasses.pl <ANDROID_DIR>
../bin/extractjar.sh
rm -f *.jar

Create a list of class name
../bin/createclasslist.sh under <ANDROID_CLASS_DIR>

----------
2: Parse all AndroidManifest.xml files (in ANDROID_DIR) for permission information

Under <ANDROID_DIR> run the following:
find -name AndroidManifest.xml > manifestlist
<PScout_DIR>/bin/parseandroidmanifest.pl > manifestpermission

grep ^contents:// manifestpermission | grep -v grantUriPermissions | sort -u > contentproviderpermission
sed -i 's/^contents/content/' contentproviderpermission
mv contentproviderpermission <ANDROID_CLASS_DIR>

grep ^PROVIDER: manifestpermission | sort -u > providerauth
mv providerauth <ANDROID_CLASS_DIR>

grep ^Intent: manifestpermission | sort -u > intentpermission
sed -i 's/^Intent://' intentpermission
mv intentpermission <ANDROID_CLASS_DIR>

Note: At this point, unless otherwise specified, all commands in future steps should be executed under <ANDROID_CLASS_DIR>

----------
3: Generate list of permissions to be analyzed by PScout

Create list of permissions available to 3rd party applications
../bin/parsepermission.pl <ANDROID_DIR>/frameworks/base/core/res/AndroidManifest.xml > permissions

Output files:
- permissions

----------
4: Testing setup

runsoot dump.DumpClass com.android.internal.telephony.gsm.GSMPhone under <ANDROID_CLASS_DIR>

If you see Exception in thread "main" java.lang.RuntimeException: couldn't find class: com.android.internal.telephony.gsm.GSMPhone$1 (is your soot-class-path set properly?) do the following:
../bin/compileemptyclass.pl com.android.internal.telephony.gsm.GSMPhone\$1

If setting is correct, there should be no errors.

----------
5: SOOT dump class information (this step should take ~day to finish)

../bin/dumpclass.sh

Output files:i
- classhierarchy
- rawcallgraph
- permissionstringusage
- message
- handlemessageswitch
- rpcmethod
- clearrestoreuid
- urifield

Note:
- modify the classlist file to change the list of class files to be processed (useful if computer died(?) in the middle of an analysis)
- the file 'processed' stores the list of classes examined so far
- run 'wc processed' to get an idea on the progress (# of lines = # classes processed)

----------
6: Build basic call graph

../bin/buildcallgraph.pl | sort -u > callgraph

Output files:
- callgraph

----------
7: Create message sending edges
../bin/analyzemessages.pl > sendmessagecallgraphedges

Output files
- sendmessagecallgraphedges

----------
8: AIDL RPC
../bin/createrpcedge.pl > aidlcallgraphedges
../bin/removerpcedge.pl > callgraphnorpc

----------
9: String permission checks
../bin/analyzepermissionusage.pl > pchk
../bin/formatpermissioncheck.pl

Output files:
- stringpermissioncheck
- sendreceivepermissioncheck

----------
10: Uri permission checks
../bin/analyzeurifield.pl > contentprovidercheck

Outputfiles:
- contentprovidercheck
- contentproviderfieldpermission

----------
11: SOOT Intents with "dynamic" send/receive permission
../bin/intentwithpermission.sh
../bin/analyzeintent.pl > intentwithdynamicpermission
cat intentpermission intentwithdynamicpermission > intentpermissions

Outputfiles:
- intentwithdynamicpermission
- intentpermissions

----------
12: SOOT Intent permission check (~day)
../bin/intentpermissioncheck.sh
../bin/analyzeintentcheck.pl > intentpermissioncheck

Outputfiles:
- intentpermissioncheck

----------
13: API mapping

cp <ANDROID_DIR>/frameworks/base/api/current.xml <ANDROID_CLASS_DIR>
Note: when analyzing android 4.0, copy current.txt instead

../bin/broadcaststickycheck.pl > broadcaststickycheck
../bin/apimapping.pl > API

Output files:
- permissionreachedprovider

----------
14: New content permission requirement found from first apimapping.pl pass

../bin/analyzereachedprovider.pl > reachedcontentproviderpermission
../bin/analyzeurifield.pl > contentproviderdynamiccheck

----------
15: Second (final) API mapping

../bin/apimapping.pl > API
grep -e ^Permission -e Callers: -e ^\< API > allmappings

Output files:
- allmappings
- publishedapimapping

----------
16: Generate some basic stats

../bin/generatestats.pl > stats

Output files:
- stats

