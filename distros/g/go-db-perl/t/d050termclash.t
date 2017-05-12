#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;
use GO::Parser;


# ----- REQUIREMENTS -----

# This test script tests the following requirements:
# GO::Parser /  GO::Verfier catches errors

# ------------------------

n_tests(3);

stmt_ok;
my $parser = new GO::Parser ({handler=>'db'});
$parser->cache_errors;
$parser->parse ("./t/data/test_bad_function.dat");
my @errs = $parser->errlist;
print $_->xml foreach @errs;
stmt_note("n errors: ".scalar(@errs));
stmt_check(@errs == 2);
# lets check we got stuff

#stmt_check($apph->get_term({acc=>9999})->name eq $apph->get_term({acc=>6099})->name);
stmt_ok;
