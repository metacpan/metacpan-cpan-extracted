#!/bin/csh

echo "Test A1a for svdpackout.pl"

cp test-A1a.matrix matrix
cp test-A1a.lap2 lap2

echo "Running las2"
las2

echo "Running svdpackout.pl --format i4 lav2 lao2 > test-A1a.output"
svdpackout.pl --format i4 lav2 lao2 > test-A1a.output

# redirect STDOUT and STDERR, both to var because svdcompare.pl right to STDERR
perl ./svdcompare.pl test-A1a.output test-A1a.reqd 1.0 >& var

if(-z var) then
	echo "Test Ok";
else
	echo "Test Error";
	echo "When tested against test-A1a.reqd";
	cat var;
endif

/bin/rm -f var t0 t1 lao2 lav2 matrix lap2 test-A1a.output 
 
echo "Test A1b for svdpackout.pl"

cp test-A1b.matrix matrix
cp test-A1b.lap2 lap2

echo "Running las2"
las2
echo "Running svdpackout.pl lav2 lao2 > test-A1b.output"
svdpackout.pl lav2 lao2 > test-A1b.output

perl ./svdcompare.pl test-A1b.output test-A1b.reqd 1.0 >& var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A1b.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 lao2 lav2 matrix lap2 test-A1b.output

echo "Test A1c for svdpackout.pl"

cp test-A1c.matrix matrix
cp test-A1c.lap2 lap2

echo "Running las2"
las2
echo "Running svdpackout.pl --format i5 lav2 lao2 > test-A1c.output"
svdpackout.pl --format i5 lav2 lao2 > test-A1c.output

perl ./svdcompare.pl test-A1c.output test-A1c.reqd 1.0 >& var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A1c.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 lao2 lav2 matrix lap2 test-A1c.output

echo "Test A1d for svdpackout.pl"

cp test-A1d.matrix matrix
cp test-A1d.lap2 lap2

echo "Running las2"
las2
echo "Running svdpackout.pl lav2 lao2 > test-A1d.output"
svdpackout.pl lav2 lao2 > test-A1d.output

perl ./svdcompare.pl test-A1d.output test-A1d.reqd 1.0 >& var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A1d.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 lao2 lav2 matrix lap2 test-A1d.output

echo "Test A1e for svdpackout.pl"

cp test-A1e.matrix matrix
cp test-A1e.lap2 lap2

echo "Running las2"
las2
echo "Running svdpackout.pl --format i4 lav2 lao2 > test-A1e.output"
svdpackout.pl --format i4 lav2 lao2 > test-A1e.output

perl ./svdcompare.pl test-A1e.output test-A1e.reqd 1.0 >& var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A1e.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 lao2 lav2 matrix lap2 test-A1e.output 

echo "Test A1f for svdpackout.pl"

cp test-A1f.matrix matrix
cp test-A1f.lap2 lap2

echo "Running las2"
las2
echo "Running svdpackout.pl lav2 lao2 > test-A1f.output"
svdpackout.pl lav2 lao2 > test-A1f.output

perl ./svdcompare.pl test-A1f.output test-A1f.reqd 1.0 >& var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A1f.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 lao2 lav2 matrix lap2 test-A1f.output

echo "Test A1g for svdpackout.pl"

cp test-A1g.matrix matrix
cp test-A1g.lap2 lap2

echo "Running las2"
las2
echo "Running svdpackout.pl --format i5 lav2 lao2 > test-A1g.output"
svdpackout.pl --format i5 lav2 lao2 > test-A1g.output

perl ./svdcompare.pl test-A1g.output test-A1g.reqd 1.0 >& var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A1g.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 lao2 lav2 matrix lap2 test-A1g.output

echo "Test A1h for svdpackout.pl"

cp test-A1h.matrix matrix
cp test-A1h.lap2 lap2

echo "Running las2"
las2
echo "Running svdpackout.pl lav2 lao2 > test-A1h.output"
svdpackout.pl lav2 lao2 > test-A1h.output

perl ./svdcompare.pl test-A1h.output test-A1h.reqd 1.0 >& var

if(-z var) then
        echo "Test Ok";
else
        echo "Test Error";
        echo "When tested against test-A1h.reqd";
        cat var;
endif

/bin/rm -f var t0 t1 lao2 lav2 matrix lap2 test-A1h.output

