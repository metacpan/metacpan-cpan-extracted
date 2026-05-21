#!/usr/bin/env perl

###################################################################################################
# Author:        Olivier Delouya
# File:          t/13-bounds-quantifiers.t
# Content:       bounds Quantifiers {n,m}
# Indent:        Whitesmith (perltidy -bl -bli)
###############################################

use strict;
use warnings;
use Test::More;
use FindBin;
use lib $FindBin::Bin; 
use File::Spec;
use lib File::Spec->catdir('.', 't');
use Helper;

# ==================================================================================================
# DAYTONA TRACK REPORT: TEST SUITE 13 - bounds Quantifiers {n,m}
# ==================================================================================================
# If the tokenizer is unaware of the {n,m} syntax, it will inevitably 
# fragment the regex into isolated literals. For instance, with 'a{3}', 
# the engine will consume the first 'a', then fatally crash upon encountering 
# the '{' character. Consequently, an expected Match Length of 0 will 
# inaccurately report as 1, and the fail token will erroneously point to '{'.
# ==================================================================================================

plan tests => 14;

sub run_bounds_quantifiers_tests
    {
    #          REGEX         INPUT      MATCH  LEN  FAIL_C  FAIL_TOKEN  LABEL                             OPT
    # -------------------------------------------------------------------------------------------------------
    # 1. Fixed Quantifier {n}
    check_tst( 'a{3}',       'aa',      0,     0,   'a',     'a{3}',     "Fixed {n}: Not enough chars",    [] );
    check_tst( 'a{3}',       'aaa',     1,     3,   '',     '',         "Fixed {n}: Exact match",         [] );
    check_tst( 'a{3}',       'aaaa',    1,     3,   '',     '',         "Fixed {n}: Too many chars",      [] );

    # 2. Closed Range {n,m}
    check_tst( 'a{2,4}',     'a',       0,     0,   'a',     'a{2,4}',   "Range {n,m}: Below min",         [] );
    check_tst( 'a{2,4}',     'aa',      1,     2,   '',     '',         "Range {n,m}: At min",            [] );
    check_tst( 'a{2,4}',     'aaa',     1,     3,   '',     '',         "Range {n,m}: Between min/max",   [] );
    check_tst( 'a{2,4}',     'aaaa',    1,     4,   '',     '',         "Range {n,m}: At max",            [] );
    check_tst( 'a{2,4}',     'aaaaa',   1,     4,   '',     '',         "Range {n,m}: Above max limit",   [] );

    # 3. Open Range {n,}
    check_tst( 'a{2,}',      'a',       0,     0,   'a',     'a{2,}',    "Open range {n,}: Below min",     [] );
    check_tst( 'a{2,}',      'aaaaa',   1,     5,   '',     '',         "Open range {n,}: Greedy match",  [] );

    # 4. Complex Sequence
    check_tst( 'a{2,3}b',    'aab',     1,     3,   '',     '',         "Sequence: Min met + suffix",     [] );
    check_tst( 'a{2,3}b',    'aaab',    1,     4,   '',     '',         "Sequence: Max met + suffix",     [] );
    check_tst( 'a{2,3}b',    'ab',      0,     0,   'a',    'a{2,3}b',  "Sequence: Min NOT met",          [] );

    # 5. Literal Braces (Edge case)
    check_tst( 'a{x}',       'a{x}',    1,     4,   '',     '',         "Literal non-quantif braces",     [] );
    }

run_bounds_quantifiers_tests();

done_testing();