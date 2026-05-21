#!/usr/bin/env perl

###############################################
# Author:        Olivier Delouya - 2026
# File:          t/03-stress.t
# Content:       Stress & Boundary tests for tstregex
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

# 1. Quantifiers: '^' is validated at index 0, waiting for the rest.
check_tst( '^\d{3}$',          '12a',    0,      0,   '1',    '\d{3}$',  'Quantifier fail'            );
check_tst( '\d{2}',            '12',     1,      2,   '',     '',        'Quantifier ok'              );

# 2. Plus-Char: Consumed 'aaa' (index 3), found 'x', expected 'b'.
check_tst( 'a+b',              'aaax',   0,      3,   'x',    'b',       'Plus-Char fail'             );

# 3. Anchors: '^' validated on empty string, waiting for the rest.
check_tst( '^abc$',            '',       0,      0,   '',     'abc$',    'Empty string fail'          );

# 4. Anchor-Char: 'ab' validated (index 2), found 'd', expected 'c$'.
check_tst( '^abc$',            'abd',    0,      2,   'd',    'c$',      'Anchor-Char fail'           );

# 5. Groups: 'abc' validated (index 3), found 'd', expected the digit.
check_tst( '(abc|def)\d+',     'abcd',   0,      3,   'd',    '\d+',     'Group then fail'            );

# 6. Total mismatch: Scanned until the end of 'abc' (index 3).
check_tst( 'xyz',              'abc',    0,      0,   'a',     'xyz',     'Total mismatch (scan)'      );

# 7. Escaped: '[' validated (index 1), found 'a', expected '\d\]'.
check_tst( '\[\d\]',           '[a]',    0,      1,   'a',    '\d\]',    'Escaped fail'               );

# 8. Short strings: Reached end of 'ab' (index 2), waiting for 'c$'.
check_tst( 'abc$',             'ab',     0,      2,   '',     'c$',      'Short string fail'          );

# 9. Complex partial: 'a.c.' validated on 'abcx'. The second '.' consumed 'x'.
# Reached index 4 (end), missing the final 'e'.
check_tst( 'a.c.e',            'abcx',   0,      4,   '',     'e',       'Complex partial fail'       );

# 10. Immediate anchor: '^' validated, waiting for 'a', found 'b'.
check_tst( '^a',               'b',      0,      0,   'b',    'a',       'Instant fail'               );

# 11. Case-Insensitive fail: Engine is case-sensitive. 
# Scans everything (3), finds nothing (''), still expects 'abc'.
check_tst( 'abc',              'ABX',    0,      0,   'A',     'abc',     'CI fail (sensitive)'        );

# 12. Long string stress: Verifying stability with 1000 characters.
my $long_a = "a" x 1000;
check_tst( 'a+',               $long_a,  1,      1000, '',    '',        'Long string match'          );

done_testing();
1;