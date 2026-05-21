#!/usr/bin/env perl

###############################################
# Author:        Olivier Delouya - 2026
# File:          t/02-captures.t
# Content:       Captures & Logic tests for tstregex
# indent:        Whitesmith (perltidy -bl -bli)
###############################################

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin; 
use Test::More;
use Helper;

plan tests => 13;

# ========================================================================================================================
# COLUMN GUIDE:
#           REGEX            | INPUT  | MATCH | LEN | FOUND | EXPECTED | DEBUG MESSAGE
# ========================================================================================================================

# Quantifiers: Can backtrack to index 0 or stop at 2. Let's not guess.
check_tst( '^\d{3}$',          '12a',    0,     '?',  '?',    '?',       'Quantifier fail'            );
check_tst( '\d{2}',            '12',     1,      2,   '',     '',        'Quantifier ok'              );

# Repetition operators: Backtracking makes the failure point debatable.
check_tst( 'a+b',              'aaax',   0,     '?',  '?',    '?',       'Plus-Char fail'             );

# Anchors: Simple enough to be precise.
check_tst( '^abc$',            '',       0,      0,   '',     'abc$',   'Empty string fail'          );
check_tst( '^abc$',            'abd',    0,     '?',  '?',    '?',       'Anchor-Char fail'           );

# Groups and alternations: Highly unpredictable failure tokens.
check_tst( '(abc|def)\d+',     'abcd',   0,     '?',  '?',    '?',       'Group then fail'            );

# Total mismatches: Usually fails immediately at index 0.
check_tst( 'xyz',              'abc',    0,      0,   'a',     'xyz',     'Total mismatch'             );

# Escaped characters
check_tst( '\[\d\]',           '[a]',    0,     '?',  '?',    '?',       'Escaped fail'               );

# Short strings: Precision is possible here.
check_tst( 'abc$',             'ab',     0,      2,   '',     'c$',     'Short string fail' );
check_tst( 'a.c.e',            'abcx',   0,     '?',  '?',    '?',       'Complex partial fail'       );

# Immediate anchor failure: Very predictable.
check_tst( '^a',               'b',      0,      0,   'b',    'a',      'Instant fail'               );

# Case-insensitive: We know it fails, but where it stops depends on CI logic.
check_tst( 'abc',              'ABX',    0,     '?',  '?',    '?',       'CI fail'                    );

# Success case: Must be 100% precise.
check_tst( 'a(b)c',            'abc',    1,      3,   '',     '',        'Simple group match'         );

done_testing();
1;