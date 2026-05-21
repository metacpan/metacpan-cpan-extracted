#!/usr/bin/env perl

###################################################################################################
# Author:        Olivier Delouya
# File:          t/12-modifiers.t
# Content:       Inline modifiers (?i) and (?s)
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
# TEST SUITE: Inline Modifiers
# Rule: (?i) toggles case-insensitivity, (?s) allows '.' to match newline characters.
# =============================================================================================================================
#            REGEX           STRING          RES  LEN  FND  EXP      DESCRIPTION                        CAPS
# =============================================================================================================================

# 1. Global Case-Insensitive
check_tst(  '(?i)abc',      "ABC",          1,   3,   '?', '?',     "Modifier (?i): simple match",     [] );

# 2. Case-Insensitive failure
check_tst(  '(?i)abc',      "ABD",          0,   2,   'D', 'c',     "Modifier (?i): failure at 'D'",   [] );

# 3. Scoped Case-Insensitive
check_tst(  '(?i)a(?-i)B',  "ab",           0,   1,   'b', 'B',     "Scoped (?i): 'b' should be 'B'",  [] );

# 4. Global Dot-All (?s)
check_tst(  '(?s)a.b',      "a\nb",         1,   3,   '?', '?',     "Modifier (?s): dot matches \n",   [] );

# 5. Dot-All failure (default behavior)
# If tstregex scanner is standard: Match length is 1, fails because '.' cannot take the \x0a.
my $nl      = chr(10);
my $with_nl = "a" . $nl . "b";
#check_tst(  'a.b',          $with_nl,       0,   1,   $nl, '.',     "Default dot: fails on real \\n",  [] );
check_tst(  'a.b',          $with_nl,       0,   1,   $nl, '?',      "Default dot: fails on real \\n", [] );

# 6. Combined modifiers
check_tst(  '(?is)A.b',     "a\nB",         1,   3,   '?', '?',     "Combined (?is): case + dot-all",  [] );

done_testing();
1;