#!perl -T

use strict;
use warnings;

use Test::More tests => 3;
use Test::NoWarnings;
use Test::HexDifferences;

# use default address and default format
eq_or_dump_diff(
    '12345678',              # got
    '1234567',               # expected
    'example with defaults', # test name
);

# use own format
# - 1 byte missing in "got".
# - 2nd word for "%2n" can not filled, so filled with space.
# - End of format.
# - Last byte will be displayd in default format.
# - This is the default behaviour in case of errors with multibytes format items.
eq_or_dump_diff(
    '12345678',             # got
    '1234567',              # expected
    {
        address => 0x1000,  # set start address
        format  => <<'EOT', # set own format
%a %N
%1x%
%a %2n
%1x%
EOT
    },
    'example with customized address and format',
);

__END__

>prove -l example\01_eq_or_dump_diff.t
example\01_eq_or_dump_diff.t .. 1/3
#   Failed test 'example with defaults'
#   at example\01_eq_or_dump_diff.t line 11.
# +---+---------------------------+---------------------------+
# | Ln|Got                        |Expected                   |
# +---+---------------------------+---------------------------+
# |  1|0000 : 31 32 33 34 : 1234  |0000 : 31 32 33 34 : 1234  |
# *  2|0004 : 35 36 37 38 : 5678  |0004 : 35 36 37    : 567   *
# +---+---------------------------+---------------------------+

#   Failed test 'example with customized address and format'
#   at example\01_eq_or_dump_diff.t line 23.
# +---+------------------+---+------------------------+
# | Ln|Got               | Ln|Expected                |
# +---+------------------+---+------------------------+
# |  1|1000 31323334     |  1|1000 31323334           |
# *  2|1004 3536 3738\n  *  2|1004 3536\s\s\s\s\s\n   *
# |   |                  *  3|1006 : 37          : 7  *
# +---+------------------+---+------------------------+
# Looks like you failed 2 tests of 3.
example\01_eq_or_dump_diff.t .. Dubious, test returned 2 (wstat 512, 0x200)
Failed 2/3 subtests

Test Summary Report
-------------------
example\01_eq_or_dump_diff.t (Wstat: 512 Tests: 3 Failed: 2)
  Failed tests:  1-2
  Non-zero exit status: 2
Files=1, Tests=3,  0 wallclock secs ( 0.11 usr +  0.00 sys =  0.11 CPU)
Result: FAIL
