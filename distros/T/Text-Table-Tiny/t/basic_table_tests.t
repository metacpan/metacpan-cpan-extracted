use strict;
use Test::More tests => 5;
use lib qw(t/lib);

BEGIN {
      use_ok('Text::Table::Tiny');
}

my $rows = [
   [ 'Elvis', 'Priscilla' ],
   [ 'Liquor', 'Beer', 'Wine' ],
   [ undef, undef, undef, "That's showbiz!" ],
];

my $t0 = Text::Table::Tiny::table( rows => $rows );
is($t0, q%+--------+-----------+------+-----------------+
| Elvis  | Priscilla |      |                 |
| Liquor | Beer      | Wine |                 |
|        |           |      | That's showbiz! |
+--------+-----------+------+-----------------+%,
'just rows'
);

my $t1 = Text::Table::Tiny::table( rows => $rows, header_row => 1 );
is($t1, q%+--------+-----------+------+-----------------+
| Elvis  | Priscilla |      |                 |
+--------+-----------+------+-----------------+
| Liquor | Beer      | Wine |                 |
|        |           |      | That's showbiz! |
+--------+-----------+------+-----------------+%,
'rows and header row');

my $t2 = Text::Table::Tiny::table( rows => $rows, separate_rows => 1 );
is($t2,q%+--------+-----------+------+-----------------+
| Elvis  | Priscilla |      |                 |
+--------+-----------+------+-----------------+
| Liquor | Beer      | Wine |                 |
+--------+-----------+------+-----------------+
|        |           |      | That's showbiz! |
+--------+-----------+------+-----------------+%,
'separate rows');

my $t3 = Text::Table::Tiny::table( rows => $rows, header_row => 1, separate_rows => 1 );
is($t3,q%+--------+-----------+------+-----------------+
| Elvis  | Priscilla |      |                 |
O========O===========O======O=================O
| Liquor | Beer      | Wine |                 |
+--------+-----------+------+-----------------+
|        |           |      | That's showbiz! |
+--------+-----------+------+-----------------+%,
'header and separate rows');
