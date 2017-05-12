# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tie::FS;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$x = tie %fs, Tie::FS;
print "not " unless defined $x;
print "ok 2\n";

{ local $/; open IN, "<MANIFEST"; $_ = <IN>; close IN; }
print "not " unless $_ eq $fs{"MANIFEST"};
print "ok 3\n";

# Should test exists, defined, length=0, length>0, errors, overwrite, clear...
