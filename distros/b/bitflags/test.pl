# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}
use bitflags qw( AB CD EF );
use bitflags qw( GH IJ KL );
use bitflags qw( :start=8 MN OP );
use bitflags qw( :start=^10 QR ST );
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$\ = "\n";

print +(AB != 1 ? "not ok " : "ok ") . 2;
print +(CD != 2 ? "not ok " : "ok ") . 3;
print +(EF != 4 ? "not ok " : "ok ") . 4;
print +(GH != 8 ? "not ok " : "ok ") . 5;
print +(IJ != 16 ? "not ok " : "ok ") . 6;
print +(KL != 32 ? "not ok " : "ok ") . 7;
print +(MN != 8 ? "not ok " : "ok ") . 8;
print +(OP != 16 ? "not ok " : "ok ") . 9;
print +(QR != 1024 ? "not ok " : "ok ") . 10;
print +(ST != 2048 ? "not ok " : "ok ") . 11; 
