#!/usr/bin/env perl

###############################################
# Author:        Olivier Delouya - 2026
# File:          t/03-stress.t
# Content:       Regexp cher classes tests for tstregex
# indent:        Whitesmith (perltidy -bl -bli)
###############################################

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin; 
use Test::More;
use Helper;

plan tests => 3;

# PATTERN      | STRING | RES | LEN | FOUND | EXPECT | DESC              | CAPS
# =================================================================================
check_tst(
  'x[0-9]z',    'x5z',    1,    3,    '',     '',      'Digit class',      []
);

check_tst(
  'x[a-z]z',    'x5z',    0,    1,    '5',    '[a-z]z', 'Class mismatch', []
);

check_tst(
  'x[a-e]z',    'xbz',    1,    3,    '',     '',      'Range match',      []
);

done_testing();
1;