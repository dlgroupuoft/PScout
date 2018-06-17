#!/bin/bash

echo Generating intent permission check...
../bin/analyzeintentcheck.pl > intentpermissioncheck

echo Generating broadcaststicky check...
../bin/broadcaststickycheck.pl > broadcaststickycheck

echo First apimapping pass...
../bin/apimapping.pl > API

echo Generating dynamic content provider check...
../bin/analyzereachedprovider.pl > reachedcontentproviderpermission
../bin/analyzeurifield.pl > contentproviderdynamiccheck

echo Second apimapping pass...
../bin/apimapping.pl > API
grep -e ^Permission -e Callers: -e ^\< API > allmappings

echo Generating stats...
../bin/generatestats.pl > stats

echo "DONE!"
