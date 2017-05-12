#!perl -T

use strict;
use warnings;

use Test::More tests => 4 + 1;
use Test::NoWarnings;
use Test::Differences;

BEGIN {
    use_ok('Test::HexDifferences::HexDump');
}

eq_or_diff(
    hex_dump("\x00"),
    "0000 : 00" . ( q{ } x 3 x (4 - 1) ) . " : .\n",
    'char NUL, default format',
);

eq_or_diff(
    hex_dump(
        "E",
        {
            address => 0xABCD,
            format  => "%4a : %1C : %d\n%*x",
        },
    ),
    "ABCD : 45 : E\n",
    'char E, single byte format',
);

eq_or_diff(
    hex_dump(
        "\x00\x01 .abc",
        {
            format => <<"EOT",
%a %2C\n%1x%
%a %5C %d\n%2x%
EOT
        },
    ),
    <<'EOT',
0000 00 01
0002 20 2E 61 62 63 ..abc
EOT
    '2 lines',
);
