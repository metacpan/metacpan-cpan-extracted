#!/bin/csh

echo "Test A8 - Testing clusterstopping.pl in vector space with delta = 0 on a contrived data to test the prediction consistency across platforms."
echo "clusterstopping.pl --prefix testA8 --measure all --delta 0 --clmethod rbr --crfun i2 --seed 5 testA8.vectors > testA8.output"

clusterstopping.pl --prefix testA8 --measure all --delta 0 --clmethod rbr --crfun i2 --seed 5 testA8.vectors > testA8.output

diff -w testA8.output testA8.reqd > var

if(-z var) then
        echo "STATUS : OK Test Results Match.";
else
        echo "STATUS : ERROR Test Results don't Match....";
        echo "When Tested Against testA8.reqd - ";
	cat var
endif

if(-e testA8.cr.dat) then
 echo "STATUS : OK File testA8.cr.dat created.";
else
 echo "STATUS : ERROR File testA8.cr.dat NOT created.";
endif

if(-e testA8.pk1) then
 echo "STATUS : OK File testA8.pk1 created.";
else
 echo "STATUS : ERROR File testA8.pk1 NOT created.";
endif

if(-e testA8.pk1.dat) then
 echo "STATUS : OK File testA8.pk1.dat created.";
else
 echo "STATUS : ERROR File testA8.pk1.dat NOT created.";
endif

if(-e testA8.pk2) then
 echo "STATUS : OK File testA8.pk2 created.";
else
 echo "STATUS : ERROR File testA8.pk2 NOT created.";
endif

if(-e testA8.pk2.dat) then
 echo "STATUS : OK File testA8.pk2.dat created.";
else
 echo "STATUS : ERROR File testA8.pk2.dat NOT created.";
endif

if(-e testA8.pk3) then
 echo "STATUS : OK File testA8.pk3 created.";
else
 echo "STATUS : ERROR File testA8.pk3 NOT created.";
endif

if(-e testA8.pk3.dat) then
 echo "STATUS : OK File testA8.pk3.dat created.";
else
 echo "STATUS : ERROR File testA8.pk3.dat NOT created.";
endif

if(-e testA8.gap) then
 echo "STATUS : OK File testA8.gap created.";
else
 echo "STATUS : ERROR File testA8.gap NOT created.";
endif

if(-e testA8.exp.dat) then
 echo "STATUS : OK File testA8.exp.dat created.";
else
 echo "STATUS : ERROR File testA8.exp.dat NOT created.";
endif

if(-e testA8.gap.dat) then
 echo "STATUS : OK File testA8.gap.dat created.";
else
 echo "STATUS : ERROR File testA8.gap.dat NOT created.";
endif

if(-e testA8.gap.log) then
 echo "STATUS : OK File testA8.gap.log created.";
else
 echo "STATUS : ERROR File testA8.gap.log NOT created.";
endif

/bin/rm -f var testA8.output testA8.cr.dat testA8.pk1 testA8.pk1.dat testA8.pk2 testA8.pk2.dat testA8.pk3 testA8.pk3.dat testA8.gap testA8.gap.dat testA8.exp.dat testA8.gap.log
