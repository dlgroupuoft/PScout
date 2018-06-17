#!/bin/bash

find -name '*.class' > classlist
sed -i 's/\.\///g' classlist
sed -i 's/\//\./g' classlist
sed -i 's/\.class$//' classlist
grep -e ^android. -e ^com. classlist > c
mv c classlist

