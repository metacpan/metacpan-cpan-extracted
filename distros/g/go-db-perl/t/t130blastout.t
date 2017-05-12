#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use Test;
use GO::TestHarness;
use GO::AppHandle;
#use GO::IO::Blast;

#use GO::Model::Graph;
# ----- REQUIREMENTS -----

# ------------------------

BEGIN {
    plan tests => 1
}

# TEST DISABLED

#my $apph = get_readonly_apph;
stmt_ok;

#$apph->filters({evcodes=>["!IEA", "!ISS"]});
#my $blast = 
#  GO::IO::Blast->new({apph=>$apph,
#                      file=>"t/data/sgd.blast.out"});#

#$blast->showgraph;
#print "\n";
#stmt_ok;
