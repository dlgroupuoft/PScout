#!/bin/bash

date
rm -f processed
for i in `cat classlist`
do
echo Processing $i ----------
time java -cp ../bin/jasminclasses-2.4.0.jar:../bin/polyglot.jar:../bin/sootclasses-2.4.0.jar:../soot/IntentPermissionCheck/bin:. IntentPermissionCheck $i>>intentcheck 2>>err
echo $i >> processed
done
date

