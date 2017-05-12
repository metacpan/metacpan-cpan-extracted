#!/usr/bin/perl -w
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}


use XML::Node;

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

print "invoking parse-testsuite.pl...\n";
require "parse-testsuite.pl";
print "ok 2\n";

print "invoking parse-orders.pl...\n";
require "parse-orders.pl";
print "ok 3\n";

print "invoking parse-foo.pl...\n";
require "parse-foo.pl";
print "ok 4\n";


