#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
BEGIN {
    eval { require Test; };
    use Test;    
    plan tests => 4;
}
use strict;
use GO::Parser;

# ----- REQUIREMENTS -----

# This test script tests the following requirements:
# mistakes in the GO files must be passed to the
# errhandler

# ------------------------

ok(1);
my $parser = 
  new GO::Parser ({format=>'go_ont'});
ok(1);
$parser->cache_errors;
$parser->parse ("./t/data/test_bad_function.dat");

my @errs = $parser->errlist;
print $_->sxpr foreach @errs;
ok(@errs == 2);
$parser->parse ("./t/data/test_bad_function.dat");
@errs = $parser->errlist;
print $_->sxpr foreach @errs;
# lets check we got stuff
ok(@errs == 2);
