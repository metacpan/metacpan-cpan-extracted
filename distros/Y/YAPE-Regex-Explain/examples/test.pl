# This file is deprecated.
# It is the original test file, but it was replaced by other tests.


# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

my $loaded;

BEGIN { $| = 1; print "1..1\n"; $^W = 1 }
END { print "not ok 1\n" unless $loaded; }
use YAPE::Regex::Explain;
use strict;

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $parser = YAPE::Regex::Explain->new(q{ foo (?(?{ $x })(?!)) b | a{2} });
print $parser->explain;
print $parser->explain('regex');
print $parser->explain('silent');

