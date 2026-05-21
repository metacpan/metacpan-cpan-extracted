#!/usr/bin/env perl

###############################################
# Author:        Olivier Delouya - 2026
# File:          t/03-stress.t
# Content:       Regexp capture logic tests for tstregex
# indent:        Whitesmith (perltidy -bl -bli)
###############################################

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin; 
use Test::More;
use Helper;

plan tests => 5;

# ========================================================================================================================
# PATTERN        | STRING    | RES | LEN | FOUND | EXPECT | DESCRIPTION                | CAPTURES
# ========================================================================================================================

check_tst(
  'a(b)c',         'abc',      1,    3,    '',     '',      'Simple group',              ['b']
);

check_tst(
  '(\d+)-(\w+)',   '42-perl',  1,    7,    '',     '',      'Two groups',                ['42', 'perl']
);

check_tst(
  '(abc)?(\d+)',   '123',      1,    3,    '',     '',      'Optional (missing)',        [undef, '123']
);

check_tst(
  '(a(b)c)',       'abc',      1,    3,    '',     '',      'Nested (outer/inner)',      ['abc', 'b']
);

check_tst( 
'(?:a(b)c)',       'abc',      1,    3,    '',     '',      'Test Non-Cap',              ['b'] );

done_testing();
1;