#!/bin/csh

echo "Test A3 - Testing clusterstopping.pl in similarity space."
echo "Running clusterstopping.pl --prefix testA3 --space similarity --measure pk testA3.vectors";

clusterstopping.pl --prefix testA3 --space similarity --measure pk testA3.simat > testA3.output

set OSNAME=`uname -s`;
if ($OSNAME == "SunOS") then
    diff -w testA3.output testA3.reqd_Sun > var
else if ($OSNAME == "Linux") then
    diff -w testA3.output testA3.reqd_Linux > var
endif

if(-z var) then
        echo "STATUS : OK Test Results Match.";
else
        echo "STATUS : ERROR Test Results don't Match....";
        echo "When Tested Against testA3.reqd - ";
	cat var
endif

if(-e testA3.cr.dat) then
 echo "STATUS : OK File testA3.cr.dat created.";
else
 echo "STATUS : ERROR File testA3.cr.dat NOT created.";
endif

if(-e testA3.pk1) then
 echo "STATUS : OK FiletestA3.pk1 created.";
else
 echo "STATUS : ERROR FiletestA3.pk1 NOT created.";
endif

if(-e testA3.pk1.dat) then
 echo "STATUS : OK FiletestA3.pk1.dat created.";
else
 echo "STATUS : ERROR FiletestA3.pk1.dat NOT created.";
endif

if(-e testA3.pk2) then
 echo "STATUS : OK FiletestA3.pk2 created.";
else
 echo "STATUS : ERROR FiletestA3.pk2 NOT created.";
endif

if(-e testA3.pk2.dat) then
 echo "STATUS : OK FiletestA3.pk2.dat created.";
else
 echo "STATUS : ERROR FiletestA3.pk2.dat NOT created.";
endif

if(-e testA3.pk3) then
 echo "STATUS : OK FiletestA3.pk3 created.";
else
 echo "STATUS : ERROR FiletestA3.pk3 NOT created.";
endif

if(-e testA3.pk3.dat) then
 echo "STATUS : OK FiletestA3.pk3.dat created.";
else
 echo "STATUS : ERROR FiletestA3.pk3.dat NOT created.";
endif

/bin/rm -f var testA3.output testA3.cr.dat testA3.pk1 testA3.pk1.dat testA3.pk2 testA3.pk2.dat testA3.pk3 testA3.pk3.dat
