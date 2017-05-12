#!/usr/local/bin/perl -w

#!/usr/bin/perl

# All tests must be run from the software directory;
# make sure we are getting the modules from here:

use lib '.';
use strict;
use Test;
BEGIN { plan tests => 1}
use GO::TestHarness;
use GO::AppHandle;

# ----- REQUIREMENTS -----

# When you get a reference, you need to know
# if it's a general reference or a definition 
# reference.

# ------------------------

my @array;

my $apph = get_readonly_apph;

## This reference should be a definition
## reference, not a general reference.

my $t = $apph->get_term({acc=>'GO:0003947'});

my $defxrefs = $t->definition_dbxref_list;
ok(grep {$_->xref_key eq '2.4.1.92'} @$defxrefs);

