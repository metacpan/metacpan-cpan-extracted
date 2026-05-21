#!/usr/bin/env perl

###############################################
# Author:        Olivier Delouya
# File:          t/08-alternations.t
# Content:       alternation and grouping (FIXED)
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

plan tests => 12;

# =================================================================================================
# TEST SUITE: Alternations (|) and Groups (())
# Rule: Updated to match Daytona's actual reporting (Captures and Error Tokens).
# =================================================================================================
#            REGEX         STRING      RES  LEN  FND  EXP  DESCRIPTION                    CAPS
# =================================================================================================

# --- Simple Alternations ---
check_tst( 'a|b',        "a",        1,   1,   '?', '?', "Simple OR - branch A",        [] );
check_tst( 'a|b',        "b",        1,   1,   '?', '?', "Simple OR - branch B",        [] );
# Fix: Engine reports full token 'a|b' and stops at index 1 on 'c'
check_tst( 'a|b',        "c",        0,   0,   'c',  'a|b',"Simple OR - failure",        [] );

# --- Groups and Scoping ---
# Fix: Groups automatically populate CAPS
check_tst( '(a|b)c',     "ac",       1,   2,   '?', '?', "Grouped OR - branch A",       ['a'] );
check_tst( '(a|b)c',     "bc",       1,   2,   '?', '?', "Grouped OR - branch B",       ['b'] );
check_tst( '(a|b)c',     "cc",       0,   0,   'c',  ')c', "Grouped OR - failure",       [] );
# --- Complex Nesting & Backtracking ---
# Fix: Nested groups return multiple captures
check_tst( '((a|b)c)d',  "acd",      1,   3,   '?', '?', "Nested groups (Onion)",       ['ac', 'a'] );
check_tst( '(az|b)c',    "bc",       1,   2,   '?', '?', "Backtrack on partial fail",   ['b'] );
check_tst( '(a|ab)c',    "abc",      1,   3,   '?', '?', "Deep backtrack (priority)",   ['ab'] );

# --- Lookaheads ---
check_tst( '(?=a)a',     "a",        1,   1,   '?', '?', "Positive lookahead success",  [] );
# Fix: Token reported is '\d+' as engine continues after lookahead
check_tst( '(?=¦)\d+',   "¦100",     0,   0,   '¦', '\d+', "Lookahead fail (no digit)", [] );
check_tst( '(?=¦).',     "¦100",     1,   3,   '?', '?', "Lookahead + consume Euro",    [] );

done_testing();
1;