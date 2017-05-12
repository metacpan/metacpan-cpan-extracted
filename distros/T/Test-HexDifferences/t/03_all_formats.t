#!perl -T

use strict;
use warnings;

use Test::More tests => 2 + 1;
use Test::NoWarnings;
use Test::Differences;

BEGIN {
    use_ok('Test::HexDifferences::HexDump');
}

my $bytes = <<"EOT";
\x11
\x21\x22\x21\x22\x21\x22
\x21\x22\x21\x22
\x41\x42\x43\x44\x41\x42\x43\x44\x41\x42\x43\x44
\x41\x42\x43\x44\x41\x42\x43\x44
\x81\x82\x83\x84\x85\x86\x87\x88
\x81\x82\x83\x84\x85\x86\x87\x88
\x81\x82\x83\x84\x85\x86\x87\x88
EOT
$bytes =~ s{\n}{}xmsg;

my $format = <<"EOT";
1 byte: %a %C\n%1x%
2 byte: %a %S %S< %S>\n%1x%
2 byte: %a %v %n\n%1x%
4 byte: %a %L %L< %L>\n%1x%
4 byte: %a %V %N\n%1x%
8 byte: %a %Q\n%1x%
8 byte: %a %Q<\n%1x%
8 byte: %a %Q>\n%1x%
EOT

# big-endian (network order) or little-endian
my $result = ( pack 'S', 1 ) eq ( pack 'n', 1 ) ? <<'EOT' : <<'EOT';
1 byte: 0000 11
2 byte: 0001 2122 2221 2122
2 byte: 0007 2221 2122
4 byte: 000B 41424344 44434241 41424344
4 byte: 0017 44434241 41424344
8 byte: 001F 8182838485868788
8 byte: 0027 8887868584838281
8 byte: 002F 8182838485868788
EOT
1 byte: 0000 11
2 byte: 0001 2221 2221 2122
2 byte: 0007 2221 2122
4 byte: 000B 44434241 44434241 41424344
4 byte: 0017 44434241 41424344
8 byte: 001F 8887868584838281
8 byte: 0027 8887868584838281
8 byte: 002F 8182838485868788
EOT

eq_or_diff(
    hex_dump(
        $bytes,
        { format => $format },
    ),
    $result,
    'all formats',
);
