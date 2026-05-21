#!/usr/bin/env perl

###############################################
# Author:        Olivier Delouya - 2026
# File:          t/01-engine.t
# Content:       Basic engine tests for tstregex
# indent:        Whitesmith (perltidy -bl -bli)
###############################################

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin; 
use Test::More;
use Helper;

# ========================================================================================================================
# COLUMN MAPPING FOR check_tst() :
# ========================================================================================================================
#          REGEX    | INPUT     | MATCH | LEN | FOUND | EXPECTED | TEST DESCRIPTION
# ========================================================================================================================

plan tests => 12;

# --- Basic tests ---
check_tst( 'abc',     'abc',      1,      3,    '',     '',        'Simple match'                 );
check_tst( 'abc',     'abd',      0,      2,    'd',    'c',       'Simple fail'                  );

# --- Anchors ---
check_tst( '^abc',    'abc',      1,      3,    '',     '',        'Start anchor ok'              );
check_tst( '^abc',    'xabc',     0,      0,    'x',    'abc',     'Start anchor fail'            );
check_tst( 'abc$',    'abc',      1,      3,    '',     '',        'End anchor ok'                );
check_tst( 'abc$',    'abcd',     0,      3,    'd',    '$',       'End anchor fail'              );

# --- Wildcards (Dot) ---
check_tst( 'a.c',     'abc',      1,      3,    '',     '',        'Dot match'                    );
check_tst( 'a.c',     'abbc',     0,      2,    'b',    'c',       'Dot fail at third atom'       );

# --- Quantifiers ---
check_tst( 'a*',      'aaaa',     1,      4,    '',     '',        'Star match'                   );
check_tst( 'a*',      'b',        1,      1,    '',     '',        'Star empty match'             );
check_tst( 'a+',      'aaaa',     1,      4,    '',     '',        'Plus match'                   );
check_tst( 'a+',      'b',        0,      0,    'b',    'a+',      'Plus fail'                    );

done_testing();
1;