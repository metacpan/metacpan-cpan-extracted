#!/usr/bin/env perl

###############################################
# Author:        Olivier Delouya
# File:          t/10-backrefs.t
# Content:       Back-references tests (\1, \2)
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

# =================================================================================================
# TEST SUITE: Back-references
# Rule: \n matches the exact same text previously captured by the n-th group.
# =================================================================================================
#            REGEX         STRING      RES  LEN  FND  EXP  DESCRIPTION                    CAPS
# =================================================================================================

# 1. Basic identity match
check_tst( '(a)x\1',     "axa",      1,   3,   '?', '?', "Simple backref success",      ['a'] );

# 2. Alternation + Backref (The choice must persist)
check_tst( '(a|b)x\1',   "axa",      1,   3,   '?', '?', "Backref with branch A",       ['a'] );
check_tst( '(a|b)x\1',   "bxb",      1,   3,   '?', '?', "Backref with branch B",       ['b'] );

# 3. THE MISMATCH TEST: Global failure means NO captures
# Original expectation was ['a'], but Daytona (correctly) returns [] on failure.
check_tst( '(a|b)x\1',   "axb",      0,   2,   'b', '\1', "Backref failure (mismatch)", [] );

# 4. Multiple captures and references
check_tst( '(a)(b)\1\2', "abab",     1,   4,   '?', '?', "Multiple backrefs \1\2",      ['a', 'b'] );

# 5. Nested backreference
check_tst( '((a)b)\2',   "aba",      1,   3,   '?', '?', "Backref to nested group",     ['ab', 'a'] );

done_testing();
1;      