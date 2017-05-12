#!/bin/csh

echo "Test A1 - Testing clusterstopping.pl with default settings."
echo "Running clusterstopping.pl --prefix testA1 testA1.vectors";

clusterstopping.pl --prefix testA1 testA1.vectors > testA1.output

set OSNAME=`uname -s`;
if ($OSNAME == "SunOS") then
    diff -w testA1.output testA1.reqd_Sun > var
else if ($OSNAME == "Linux") then
    diff -w testA1.output testA1.reqd_Linux > var
endif

if(-z var) then
        echo "STATUS : OK Test Results Match.";
else
        echo "STATUS : ERROR Test Results don't Match....";
        echo "When Tested Against testA1.reqd - ";
	cat var
endif

if(-e testA1.cr.dat) then
 echo "STATUS : OK File testA1.cr.dat created.";
else
 echo "STATUS : ERROR File testA1.cr.dat NOT created.";
endif

if(-e testA1.pk3) then
 echo "STATUS : OK File testA1.pk3 created.";
else
 echo "STATUS : ERROR File testA1.pk3 NOT created.";
endif

if(-e testA1.pk3.dat) then
 echo "STATUS : OK File testA1.pk3.dat created.";
else
 echo "STATUS : ERROR File testA1.pk3.dat NOT created.";
endif

/bin/rm -f var testA1.output testA1.cr.dat testA1.pk3 testA1.pk3.dat
