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

# handle non existent terms gratefully

# ------------------------

my $apph = get_readonly_apph();
my $g = $apph->get_graph(-acc=>-5);
stmt_check($g->node_count == 0);
