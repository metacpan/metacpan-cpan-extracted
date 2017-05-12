#!/usr/local/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl access.t'

# This checks to see that UMLS-Interface will load properly

##################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use UMLS::Interface;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

