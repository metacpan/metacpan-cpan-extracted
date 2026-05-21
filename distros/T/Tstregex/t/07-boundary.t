#!/usr/bin/env perl

###############################################
# Author:        Olivier Delouya
# File:          t/07-boundary.t
# Content:       boundary tests for tstregex
# indent:        Whitesmith (perltidy -bl -bli)
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

# ==============================================================================
# TEST SUITE: Word Boundaries (\b)
# Rule: \b matches at the position between a \w and a \W character.
# ==============================================================================
#           REGEX        STRING          RES  LEN  FND  EXP  DESCRIPTION                CAPS
# ==============================================================================
check_tst( '\bcat',     "cat",           1,   3,   '?', '?', "Start boundary",           [] );
check_tst( 'cat\b',     "cat",           1,   3,   '?', '?', "End boundary",             [] );
check_tst( 'ca\bt',     "cat",           0,   2,   't', '\b', "Middle (no boundary)",    [] );
check_tst( 'cat\b ',    "cat ",          1,   4,   '?', '?', "Boundary before space",    [] );
check_tst( '\bcat',     "!cat",          1,   4,   '?', '?', "Boundary after punct",     [] );
check_tst( '\bcat\b',   "the cat sits",  1,   7,   '?', '?', "Isolated word",            [] );

done_testing();
1;