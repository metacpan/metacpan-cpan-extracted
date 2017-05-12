#!/bin/bash
for i in *.html;
do
mv $i `basename $i .html`.java 
done
