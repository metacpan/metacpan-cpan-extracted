#!/usr/bin/env perl

###############################################
# Author:        Olivier Delouya
# File:          t/09-lazy.t
# Content:       Lazy (non-greedy) quantifier tests
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

plan tests => 5;

# =============================================================================================
# TEST SUITE: Lazy Quantifiers (*?, +?, ??)
# Rule: Match as little as possible while allowing the global match to succeed.
# =============================================================================================
#            REGEX      STRING      RES  LEN  FND  EXP  DESCRIPTION                        CAPS
# =============================================================================================

# 1. Minimal match for plus
check_tst( 'a+?',      "aaaa",     1,   1,   '?', '?', "Lazy plus: stop at first match",  [] );

# 2. Lazy plus needing a delimiter to stop
check_tst( 'a+?b',     "aaab",     1,   4,   '?', '?', "Lazy plus: forced to expand",     [] );

# 3. Lazy star: the minimum is zero
check_tst( 'a*?',      "aaaa",     1,   0,   '?', '?', "Lazy star: matches empty",        [] );

# 4. Lazy optional: prefers zero over one
check_tst( 'a??',      "aaaa",     1,   0,   '?', '?', "Lazy optional: matches empty",    [] );

# 5. The classic 'stop at first' test
check_tst( '.*?b',     "aaabcccb", 1,   4,   '?', '?', "Lazy dot: stop at first 'b'",     [] );

done_testing();
1;