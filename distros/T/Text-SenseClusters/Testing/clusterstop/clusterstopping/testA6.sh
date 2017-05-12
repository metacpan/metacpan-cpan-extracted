#!/bin/csh

echo "Test A6 - Testing clusterstopping.pl in vector space using all options."
echo "Running clusterstopping.pl --clmethod direct --crfun i1 --measure all testA6.vectors"

clusterstopping.pl --prefix testA6 -clmethod direct --crfun i1 --measure all --seed 7 testA6.vectors > testA6.output

set OSNAME=`uname -s`;
if ($OSNAME == "SunOS") then
    diff -w testA6.output testA6.reqd_Sun > var
else if ($OSNAME == "Linux") then
    diff -w testA6.output testA6.reqd_Linux > var
endif

if(-z var) then
        echo "STATUS : OK Test Results Match.";
else
        echo "STATUS : ERROR Test Results don't Match....";
        echo "When Tested Against testA6.reqd - ";
	cat var
endif

if(-e testA6.cr.dat) then
 echo "STATUS : OK File testA6.cr.dat created.";
else
 echo "STATUS : ERROR File testA6.cr.dat NOT created.";
endif

if(-e testA6.pk1) then
 echo "STATUS : OK FiletestA6.pk1 created.";
else
 echo "STATUS : ERROR FiletestA6.pk1 NOT created.";
endif

if(-e testA6.pk1.dat) then
 echo "STATUS : OK FiletestA6.pk1.dat created.";
else
 echo "STATUS : ERROR FiletestA6.pk1.dat NOT created.";
endif

if(-e testA6.pk2) then
 echo "STATUS : OK FiletestA6.pk2 created.";
else
 echo "STATUS : ERROR FiletestA6.pk2 NOT created.";
endif

if(-e testA6.pk2.dat) then
 echo "STATUS : OK FiletestA6.pk2.dat created.";
else
 echo "STATUS : ERROR FiletestA6.pk2.dat NOT created.";
endif

if(-e testA6.pk3) then
 echo "STATUS : OK FiletestA6.pk3 created.";
else
 echo "STATUS : ERROR FiletestA6.pk3 NOT created.";
endif

if(-e testA6.pk3.dat) then
 echo "STATUS : OK FiletestA6.pk3.dat created.";
else
 echo "STATUS : ERROR FiletestA6.pk3.dat NOT created.";
endif

if(-e testA6.gap) then
 echo "STATUS : OK FiletestA6.gap created.";
else
 echo "STATUS : ERROR FiletestA6.gap NOT created.";
endif

if(-e testA6.exp.dat) then
 echo "STATUS : OK File testA6.exp.dat created.";
else
 echo "STATUS : ERROR File testA6.exp.dat NOT created.";
endif

if(-e testA6.gap.dat) then
 echo "STATUS : OK File testA6.gap.dat created.";
else
 echo "STATUS : ERROR File testA6.gap.dat NOT created.";
endif

if(-e testA6.gap.log) then
 echo "STATUS : OK File testA6.gap.log created.";
else
 echo "STATUS : ERROR File testA6.gap.log NOT created.";
endif

/bin/rm -f var testA6.output testA6.cr.dat testA6.pk1 testA6.pk1.dat testA6.pk2 testA6.pk2.dat testA6.pk3 testA6.pk3.dat testA6.gap testA6.gap.dat testA6.exp.dat testA6.gap.log
