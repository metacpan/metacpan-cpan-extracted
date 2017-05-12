#!/bin/csh

echo "Test A4 - Testing clusterstopping.pl in similarity space with all options."
echo "Running clusterstopping.pl --prefix testA4 --measure all --space similarity --delta 2 --clmethod rbr --crfun i2 --threspk1 -0.6 --seed 5 testA4.simat"

clusterstopping.pl --prefix testA4 --measure all --space similarity --delta 2 --clmethod rbr --crfun i2 --threspk1 -0.6 --seed 5 testA4.simat > testA4.output

set OSNAME=`uname -s`;
if ($OSNAME == "SunOS") then
    diff -w testA4.output testA4.reqd_Sun > var
else if ($OSNAME == "Linux") then
    diff -w testA4.output testA4.reqd_Linux > var
endif

if(-z var) then
        echo "STATUS : OK Test Results Match.";
else
        echo "STATUS : ERROR Test Results don't Match....";
        echo "When Tested Against testA4.reqd - ";
	cat var
endif

if(-e testA4.cr.dat) then
 echo "STATUS : OK File testA4.cr.dat created.";
else
 echo "STATUS : ERROR File testA4.cr.dat NOT created.";
endif

if(-e testA4.pk1) then
 echo "STATUS : OK File testA4.pk1 created.";
else
 echo "STATUS : ERROR File testA4.pk1 NOT created.";
endif

if(-e testA4.pk1.dat) then
 echo "STATUS : OK File testA4.pk1.dat created.";
else
 echo "STATUS : ERROR File testA4.pk1.dat NOT created.";
endif

if(-e testA4.pk2) then
 echo "STATUS : OK File testA4.pk2 created.";
else
 echo "STATUS : ERROR File testA4.pk2 NOT created.";
endif

if(-e testA4.pk2.dat) then
 echo "STATUS : OK File testA4.pk2.dat created.";
else
 echo "STATUS : ERROR File testA4.pk2.dat NOT created.";
endif

if(-e testA4.pk3) then
 echo "STATUS : OK File testA4.pk3 created.";
else
 echo "STATUS : ERROR File testA4.pk3 NOT created.";
endif

if(-e testA4.pk3.dat) then
 echo "STATUS : OK File testA4.pk3.dat created.";
else
 echo "STATUS : ERROR File testA4.pk3.dat NOT created.";
endif

if(-e testA4.gap) then
 echo "STATUS : OK File testA4.gap created.";
else
 echo "STATUS : ERROR File testA4.gap NOT created.";
endif

if(-e testA4.exp.dat) then
 echo "STATUS : OK File testA4.exp.dat created.";
else
 echo "STATUS : ERROR File testA4.exp.dat NOT created.";
endif

if(-e testA4.gap.dat) then
 echo "STATUS : OK File testA4.gap.dat created.";
else
 echo "STATUS : ERROR File testA4.gap.dat NOT created.";
endif

if(-e testA4.gap.log) then
 echo "STATUS : OK File testA4.gap.log created.";
else
 echo "STATUS : ERROR File testA4.gap.log NOT created.";
endif

/bin/rm -f var testA4.output testA4.cr.dat testA4.pk1 testA4.pk1.dat testA4.pk2 testA4.pk2.dat testA4.pk3 testA4.pk3.dat testA4.gap testA4.gap.dat testA4.exp.dat testA4.gap.log
