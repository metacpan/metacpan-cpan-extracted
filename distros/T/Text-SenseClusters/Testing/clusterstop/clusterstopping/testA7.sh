#!/bin/csh

echo "Test A7 - Testing clusterstopping.pl in vector space with delta = 0 and all options."
echo "clusterstopping.pl --prefix testA7 --measure all --delta 0 --clmethod rbr --crfun i2 --seed 5 testA7.vectors > testA7.output"

clusterstopping.pl --prefix testA7 --measure all --delta 0 --clmethod rbr --crfun i2 --seed 5 testA7.vectors > testA7.output

set OSNAME=`uname -s`;
if ($OSNAME == "SunOS") then
    diff -w testA7.output testA7.reqd_Sun > var
else if ($OSNAME == "Linux") then
    diff -w testA7.output testA7.reqd_Linux > var
endif

if(-z var) then
        echo "STATUS : OK Test Results Match.";
else
        echo "STATUS : ERROR Test Results don't Match....";
        echo "When Tested Against testA7.reqd - ";
	cat var
endif

if(-e testA7.cr.dat) then
 echo "STATUS : OK File testA7.cr.dat created.";
else
 echo "STATUS : ERROR File testA7.cr.dat NOT created.";
endif

if(-e testA7.pk1) then
 echo "STATUS : OK File testA7.pk1 created.";
else
 echo "STATUS : ERROR File testA7.pk1 NOT created.";
endif

if(-e testA7.pk1.dat) then
 echo "STATUS : OK File testA7.pk1.dat created.";
else
 echo "STATUS : ERROR File testA7.pk1.dat NOT created.";
endif

if(-e testA7.pk2) then
 echo "STATUS : OK File testA7.pk2 created.";
else
 echo "STATUS : ERROR File testA7.pk2 NOT created.";
endif

if(-e testA7.pk2.dat) then
 echo "STATUS : OK File testA7.pk2.dat created.";
else
 echo "STATUS : ERROR File testA7.pk2.dat NOT created.";
endif

if(-e testA7.pk3) then
 echo "STATUS : OK File testA7.pk3 created.";
else
 echo "STATUS : ERROR File testA7.pk3 NOT created.";
endif

if(-e testA7.pk3.dat) then
 echo "STATUS : OK File testA7.pk3.dat created.";
else
 echo "STATUS : ERROR File testA7.pk3.dat NOT created.";
endif

if(-e testA7.gap) then
 echo "STATUS : OK File testA7.gap created.";
else
 echo "STATUS : ERROR File testA7.gap NOT created.";
endif

if(-e testA7.exp.dat) then
 echo "STATUS : OK File testA7.exp.dat created.";
else
 echo "STATUS : ERROR File testA7.exp.dat NOT created.";
endif

if(-e testA7.gap.dat) then
 echo "STATUS : OK File testA7.gap.dat created.";
else
 echo "STATUS : ERROR File testA7.gap.dat NOT created.";
endif

if(-e testA7.gap.log) then
 echo "STATUS : OK File testA7.gap.log created.";
else
 echo "STATUS : ERROR File testA7.gap.log NOT created.";
endif

/bin/rm -f var testA7.output testA7.cr.dat testA7.pk1 testA7.pk1.dat testA7.pk2 testA7.pk2.dat testA7.pk3 testA7.pk3.dat testA7.gap testA7.gap.dat testA7.exp.dat testA7.gap.log
