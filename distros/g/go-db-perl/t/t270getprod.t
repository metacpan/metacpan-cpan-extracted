#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:

use lib '.';
use strict;
use Test;
BEGIN { plan tests => 1 }
use GO::TestHarness;
set_n_tests(1);
use GO::AppHandle;

# ----- REQUIREMENTS -----

# ------------------------

my $apph = get_readonly_apph();
$apph->filters->{speciesdb} = ['sgd'];
my $p = $apph->get_product;
my $tl = $apph->get_terms({products=>[{acc=>$p->acc}]});
my $tl2 = $apph->get_terms({products=>$p->symbol});
sub j { join(" ", map {$_->acc} @_) }
stmt_note(j(@$tl));
stmt_note(j(@$tl2));
stmt_check(j(@$tl) eq j(@$tl2));
