#!/bin/csh

echo "Test A3a for svdpackout.pl"

cp test-A3a.matrix matrix
cp test-A3a.lap2 lap2

echo "Running las2"
las2

echo "Running svdpackout.pl --format i4 lav2 lao2 > test-A3a.output"
svdpackout.pl --format i4 lav2 lao2 > test-A3a.output

perl ./svdcompare.pl test-A3a.output test-A3a.reqd 1 >& var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A3a.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 lao2 lav2 matrix lap2 test-A3a.output

echo "Test A3b for svdpackout.pl"

cp test-A3b.matrix matrix
cp test-A3b.lap2 lap2

echo "Running las2"
las2
echo "Running svdpackout.pl lav2 lao2 > test-A3b.output"
svdpackout.pl lav2 lao2 > test-A3b.output

perl ./svdcompare.pl test-A3b.output test-A3b.reqd 0.1 >& var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A3b.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 lao2 lav2 matrix lap2 test-A3b.output

echo "Test A3c for svdpackout.pl"

cp test-A3c.matrix matrix
cp test-A3c.lap2 lap2

echo "Running las2"
las2
echo "Running svdpackout.pl --format i5 lav2 lao2 > test-A3c.output"
svdpackout.pl --format i5 lav2 lao2 > test-A3c.output

perl ./svdcompare.pl test-A3c.output test-A3c.reqd 1 >& var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A3c.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 lao2 lav2 matrix lap2 test-A3c.output

echo "Test A3d for svdpackout.pl"

cp test-A3d.matrix matrix
cp test-A3d.lap2 lap2

echo "Running las2"
las2
echo "Running svdpackout.pl lav2 lao2 > test-A3d.output"
svdpackout.pl lav2 lao2 > test-A3d.output

perl ./svdcompare.pl test-A3d.output test-A3d.reqd 0.1 >& var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A3d.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 lao2 lav2 matrix lap2 test-A3d.output

echo "Test A3e for svdpackout.pl"

cp test-A3e.matrix matrix
cp test-A3e.lap2 lap2

echo "Running las2"
las2
echo "Running svdpackout.pl --format i5 lav2 lao2 > test-A3e.output"
svdpackout.pl --format i5 lav2 lao2 > test-A3e.output

perl ./svdcompare.pl test-A3e.output test-A3e.reqd 1 >& var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A3e.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 lao2 lav2 matrix lap2 test-A3e.output

echo "Test A3f for svdpackout.pl"

cp test-A3f.matrix matrix
cp test-A3f.lap2 lap2

echo "Running las2"
las2
echo "Running svdpackout.pl lav2 lao2 > test-A3f.output"
svdpackout.pl lav2 lao2 > test-A3f.output

perl ./svdcompare.pl test-A3f.output test-A3f.reqd 2 >& var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A3f.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 lao2 lav2 matrix lap2 test-A3f.output

