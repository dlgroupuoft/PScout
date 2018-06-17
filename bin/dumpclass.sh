#!/bin/bash

date
for i in `cat classlist`
do
echo Processing $i ----------
time java -cp ../bin/jasminclasses-2.4.0.jar:../bin/polyglot.jar:../bin/sootclasses-2.4.0.jar:../soot/DumpClass/bin:. dump.DumpClass $i 2>>err
cat ch >> classhierarchy
sort -u rcg >> rawcallgraph
cat pstr >> permissionstringusage
cat pstrf >> permissionstringusageflow
cat msg >> message
cat switch >> handlemessageswitch
cat rpc >> rpcmethod
sort -u uid >> clearrestoreuid
cat uri >> urifield
echo $i >> processed
done
date

