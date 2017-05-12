#!/bin/csh

echo "Test A5 - Testing clusterstopping.pl in vector space using all options."
echo "Running clusterstopping.pl --prefix testA5 --measure all --space vector --delta 2 --clmethod bagglo --crfun h1 --sim corr --rowmodel log --colmodel idf testA5.vectors";

clusterstopping.pl --prefix testA5 --measure pk --space vector --delta 2 --clmethod bagglo --crfun h1 --sim corr --rowmodel log --colmodel idf testA5.vectors > testA5.output

set OSNAME=`uname -s`;
if ($OSNAME == "SunOS") then
    diff -w testA5.output testA5.reqd_Sun > var
else if ($OSNAME == "Linux") then
    diff -w testA5.output testA5.reqd_Linux > var
endif

if(-z var) then
        echo "STATUS : OK Test Results Match.";
else
        echo "STATUS : ERROR Test Results don't Match....";
        echo "When Tested Against testA5.reqd - ";
	cat var
endif

if(-e testA5.cr.dat) then
 echo "STATUS : OK File testA5.cr.dat created.";
else
 echo "STATUS : ERROR File testA5.cr.dat NOT created.";
endif

if(-e testA5.pk1) then
 echo "STATUS : OK FiletestA5.pk1 created.";
else
 echo "STATUS : ERROR FiletestA5.pk1 NOT created.";
endif

if(-e testA5.pk1.dat) then
 echo "STATUS : OK FiletestA5.pk1.dat created.";
else
 echo "STATUS : ERROR FiletestA5.pk1.dat NOT created.";
endif

if(-e testA5.pk2) then
 echo "STATUS : OK FiletestA5.pk2 created.";
else
 echo "STATUS : ERROR FiletestA5.pk2 NOT created.";
endif

if(-e testA5.pk2.dat) then
 echo "STATUS : OK FiletestA5.pk2.dat created.";
else
 echo "STATUS : ERROR FiletestA5.pk2.dat NOT created.";
endif

if(-e testA5.pk3) then
 echo "STATUS : OK FiletestA5.pk3 created.";
else
 echo "STATUS : ERROR FiletestA5.pk3 NOT created.";
endif

if(-e testA5.pk3.dat) then
 echo "STATUS : OK FiletestA5.pk3.dat created.";
else
 echo "STATUS : ERROR FiletestA5.pk3.dat NOT created.";
endif

/bin/rm -f var testA5.output testA5.cr.dat testA5.pk1 testA5.pk1.dat testA5.pk2 testA5.pk2.dat testA5.pk3 testA5.pk3.dat
