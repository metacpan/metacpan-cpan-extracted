#!/bin/sh

podselect -s "NAME" -s "SYNOPSIS" -s "DESCRIPTION" lib/WebService/ILS.pm > Readme.pod
cat t/lib/T/Test.pod >> Readme.pod
