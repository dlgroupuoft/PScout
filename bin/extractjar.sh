#!/bin/bash

for i in `ls *.jar`
do
jar xf $i
done

