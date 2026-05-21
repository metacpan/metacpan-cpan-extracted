#!/usr/bin/env perl

###############################################
# Author:        Olivier Delouya
# File:          t/06-greedy.t
# Content:       Non-greedy quantifier tests for tstregex
# indent:        Whitesmith (perltidy -bl -bli)
###############################################

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin; 
use Test::More;
use Helper;

plan tests => 6;

# PATTERN      | STRING       | RES | LEN | FOUND | EXPECT | DESC              | CAPS
# =====================================================================================
check_tst(
    'a+?',        'aaaa',        1,    1,    '',     '',      'Minimal plus',     []
);

check_tst(
    'a*?',        'aaaa',        1,    0,    '',     '',      'Minimal star',     []
);

check_tst(
    "<a>.*?</a>", "<a>f</a><a>", 1,   11,    '?',    '?',     'Shortest tag',     []);

check_tst(
    'ab*?',       'abbb',        1,    1,    '',     '',      'Non-greedy at end',[]
);

check_tst(
    '^a+?b',      'aaab',        1,    4,    '',     '',      'Anchor with plus', []
);

check_tst(
    'a.*?',       'abc',         1,    1,    '',     '',      'Dot non-greedy',   []
);

done_testing();
1;