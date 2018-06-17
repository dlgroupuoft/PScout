#!/bin/bash

date

../bin/buildcallgraph.pl | sort -u > callgraph
../bin/analyzemessages.pl > sendmessagecallgraphedges
../bin/createrpcedge.pl > aidlcallgraphedges
../bin/removerpcedge.pl > callgraphnorpc
../bin/analyzepermissionusage.pl > pchk
../bin/formatpermissioncheck.pl
../bin/analyzeurifield.pl > contentprovidercheck

date

