#!/bin/csh

echo "Test A2 - Testing clusterstopping.pl when using all measures."
echo "Running clusterstopping.pl --prefix testA2 --measure all --clmethod rbr --crfun e1 --precision 6 --seed 3 testA2.vectors";

clusterstopping.pl --prefix testA2 --measure all --clmethod rbr --crfun e1 --precision 6 --seed 3 testA2.vectors > testA2.output

set OSNAME=`uname -s`;
if ($OSNAME == "SunOS") then
    diff -w testA2.output testA2.reqd_Sun > var
else if ($OSNAME == "Linux") then
    diff -w testA2.output testA2.reqd_Linux > var
endif

if(-z var) then
        echo "STATUS : OK Test Results Match.";
else
        echo "STATUS : ERROR Test Results don't Match....";
        echo "When Tested Against testA2.reqd - ";
	cat var
endif

if(-e testA2.cr.dat) then
 echo "STATUS : OK File testA2.cr.dat created.";
else
 echo "STATUS : ERROR File testA2.cr.dat NOT created.";
endif

if(-e testA2.pk1) then
 echo "STATUS : OK File testA2.pk1 created.";
else
 echo "STATUS : ERROR File testA2.pk1 NOT created.";
endif

if(-e testA2.pk1.dat) then
 echo "STATUS : OK File testA2.pk1.dat created.";
else
 echo "STATUS : ERROR File testA2.pk1.dat NOT created.";
endif

if(-e testA2.pk2) then
 echo "STATUS : OK File testA2.pk2 created.";
else
 echo "STATUS : ERROR File testA2.pk2 NOT created.";
endif

if(-e testA2.pk2.dat) then
 echo "STATUS : OK File testA2.pk2.dat created.";
else
 echo "STATUS : ERROR File testA2.pk2.dat NOT created.";
endif

if(-e testA2.pk3) then
 echo "STATUS : OK File testA2.pk3 created.";
else
 echo "STATUS : ERROR File testA2.pk3 NOT created.";
endif

if(-e testA2.pk3.dat) then
 echo "STATUS : OK File testA2.pk3.dat created.";
else
 echo "STATUS : ERROR File testA2.pk3.dat NOT created.";
endif

if(-e testA2.exp.dat) then
 echo "STATUS : OK File testA2.exp.dat created.";
else
 echo "STATUS : ERROR File testA2.exp.dat NOT created.";
endif

if(-e testA2.gap) then
 echo "STATUS : OK File testA2.gap created.";
else
 echo "STATUS : ERROR File testA2.gap NOT created.";
endif

if(-e testA2.gap.dat) then
 echo "STATUS : OK File testA2.gap.dat created.";
else
 echo "STATUS : ERROR File testA2.gap.dat NOT created.";
endif

if(-e testA2.gap.log) then
 echo "STATUS : OK File testA2.gap.log created.";
else
 echo "STATUS : ERROR File testA2.gap.log NOT created.";
endif

/bin/rm -f var testA2.output testA2.cr.dat testA2.pk1 testA2.pk1.dat testA2.pk2 testA2.pk2.dat testA2.pk3 testA2.pk3.dat testA2.gap testA2.gap.dat testA2.exp.dat testA2.gap.log
