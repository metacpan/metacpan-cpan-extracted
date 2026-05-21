#!/usr/bin/env perl

###############################################
# Author:        Olivier Delouya
# File:          t/11-quantifiers-range.t
# Content:       Fixed and range quantifiers {n,m}
# Indent:        Whitesmith (perltidy -bl -bli)
###############################################

use strict;
use warnings;
use File::Spec;
use lib File::Spec->catdir('.', 't');
use FindBin;
use lib $FindBin::Bin; 
use Test::More;
use Helper;

plan tests => 6;

# =============================================================================================================================
# TEST SUITE: Range Quantifiers {n}, {n,}, {n,m}
# Rule: {n,m} matches from n to m times the preceding element. Greedy by default.
# =============================================================================================================================
#            REGEX           STRING          RES  LEN  FND  EXP      DESCRIPTION                        CAPS
# =============================================================================================================================

# 1. Exact match {n}
check_tst(  'a{3}',         "aaaaa",        1,   3,   '?', '?',     "Fixed count: exact 3",            [] );

# 2. Exact match failure (not enough chars)
check_tst(  'a{3}',         "aa",           0,   0,   'a',  'a{3}',  "Fixed count: failure",            [] );

# 3. Range match {n,m} (Greedy)
check_tst(  'a{2,4}',       "aaaaa",        1,   4,   '?', '?',     "Range: greedy max 4",             [] );

# 4. Open range {n,} (To infinity)
check_tst(  'a{2,}',        "aaaaa",        1,   5,   '?', '?',     "Open range: match all",           [] );

# 5. Range failure (below minimum)
check_tst(  'a{3,5}',       "aa",           0,   0,   'a',  'a{3,5}', "Range: below minimum",           [] );

# 6. Lazy range {n,m}? (Minimalist)
check_tst(  'a{2,4}?',      "aaaaa",        1,   2,   '?', '?',     "Lazy range: stop at min 2",       [] );

done_testing();
1;