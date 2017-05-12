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
use GO::Model::TreeIterator;

# ----- REQUIREMENTS -----

# Comments are in the defs file, they have a line
# beneath the definition references that start with
# comment:

# We should be able to search on these as well as
# display them.

# ------------------------

my @array;

my $apph = get_readonly_apph;

## This reference should be a definition
## reference, not a general reference.

my $terms = $apph->get_terms({search=>"*obsolete*",
                              search_fields=>"comment"},
                             {acc=>1});

stmt_check(scalar(@$terms) > 0);
