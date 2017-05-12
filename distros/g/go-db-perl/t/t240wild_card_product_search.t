#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:

use lib '.';
use strict;
use Test;
BEGIN { plan tests => 4, todo => [2] }   
use GO::TestHarness;
use GO::AppHandle;

# ----- REQUIREMENTS -----

# ------------------------

#n_tests(7);

#stmt_ok;
#exit 0;

my $apph = get_readonly_apph();

my $product = $apph->get_terms({'products'=>'cat'});

stmt_ok;

$product = $apph->get_terms({'products'=>'ca*'});

stmt_check( scalar(@$product) > 0 );

#my $terms = $apph->get_terms({'products'=>{'full_name'=>'E2F transcription factor 4'}});

stmt_ok;

#$terms = $apph->get_terms({'products'=>{'full_name'=>'E2F transcription factor*'}});

#stmt_check( scalar(@$terms) > 0 );

stmt_ok;
