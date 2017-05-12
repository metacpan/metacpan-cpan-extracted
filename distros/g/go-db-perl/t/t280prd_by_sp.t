#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:

use lib '.';
use strict;
use Test;
BEGIN { plan tests => 1 }
use GO::TestHarness;
use GO::AppHandle;

# ----- REQUIREMENTS -----

# ------------------------

my $apph = get_readonly_apph();
my $pl = $apph->get_products({speciesdb=>"zzzzzzzzzz"});
stmt_check(!@$pl)
