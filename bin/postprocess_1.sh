#!/bin/bash

echo Building basic callgraph...
../bin/buildcallgraph.pl | sort -u > callgraph

echo Creating send messages edges...
../bin/analyzemessages.pl > sendmessagecallgraphedges

echo Creating RPC edges...
../bin/createrpcedge.pl > aidlcallgraphedges

echo Removing RPC edges...
../bin/removerpcedge.pl > callgraphnorpc

echo Generating permission string checks...
../bin/analyzepermissionusage.pl > pchk
../bin/formatpermissioncheck.pl

echo Generating content provider checks...
../bin/analyzeurifield.pl > contentprovidercheck

echo Identifying intents with dynamic permission...
../bin/intentwithpermission.sh
../bin/analyzeintent.pl > intentwithdynamicpermission

echo "Please run ../bin/intentpermissioncheck.sh"
