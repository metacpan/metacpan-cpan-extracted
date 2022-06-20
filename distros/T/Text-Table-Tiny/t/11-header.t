#!perl
# t/11-header.t - tests for the "header" argument
use strict;
use warnings;
use Test::More;
use Text::Table::Tiny qw/ generate_table /;
use Test::Fatal;

my $header = [qw/ Fruit Colour /];
my $rows = [
    [qw/ Apple Green /],
    [qw/ Banana Yellow /],
    [qw/ Orange Orange /],
];

my $t0 = generate_table( rows => $rows, header => $header );
is($t0, q%+--------+--------+
| Fruit  | Colour |
+--------+--------+
| Apple  | Green  |
| Banana | Yellow |
| Orange | Orange |
+--------+--------+%,
'table with separate header'
);

like(
    exception { generate_table(rows => $rows, header => $header, header_row => 1) },
    qr/header and header_row/,
    "you can't pass both 'header' and 'header_row' options"
);

like(
    exception { generate_table(header => $header) },
    qr/you must pass the 'rows' argument/,
    "passing a header without rows should croak"
);

like(
    exception { generate_table(rows => $rows, header => "Fruit Colour") },
    qr/the 'header' argument expects an arrayref/,
    "passing something other than arrayref for header should croak"
);

done_testing();
