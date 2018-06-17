#!/bin/bash

#for i in `cat sendreceivepermissioncheck`
#do
#echo Processing $i ----------
#java -cp ../bin/jasminclasses-2.4.0.jar:../bin/polyglot.jar:../bin/sootclasses-2.4.0.jar:../soot/IntentWithPermission/bin:. IntentWithPermission $i 2>>err
#echo $i >> processed
#done

rm -f intent intenterr

cat sendreceivepermissioncheck | while read i; do
echo ---------- $i ----------
echo ---------- $i ---------- >> intent
java -cp ../bin/jasminclasses-2.4.0.jar:../bin/polyglot.jar:../bin/sootclasses-2.4.0.jar:../soot/IntentWithPermission/bin:. IntentWithPermission "$i" 1>>intent 2>>intenterr
#echo $i >> processed
done

