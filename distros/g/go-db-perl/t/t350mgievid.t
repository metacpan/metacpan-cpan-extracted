#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:

use lib '.';
use strict;
use Test;
BEGIN { plan tests => 2}
use GO::Model::Evidence;
use GO::AppHandle;

# ----- REQUIREMENTS -----

# ------------------------

my $ev = GO::Model::Evidence->new({reference=>"MGI:MGI:110011"});
use Data::Dumper;
print Dumper $ev;
ok($ev->xref->xref_dbname eq "mgi");
ok($ev->xref->xref_key eq "MGI:110011");
