use strict;
use Test::More tests => 5;
use Vote::Count::TextTableTiny qw/ generate_table /;

my $rows = [
   [ 'Elvis', 'Priscilla' ],
   [ 'Liquor', 'Beer', 'Wine' ],
   [ undef, undef, undef, "That's showbiz!" ],
];

my $t0 = generate_table( rows => $rows );
is($t0, q%+--------+-----------+------+-----------------+
| Elvis  | Priscilla |      |                 |
| Liquor | Beer      | Wine |                 |
|        |           |      | That's showbiz! |
+--------+-----------+------+-----------------+%,
'just rows'
);

my $t1 = generate_table( rows => $rows, header_row => 1 );
is($t1, q%+--------+-----------+------+-----------------+
| Elvis  | Priscilla |      |                 |
+--------+-----------+------+-----------------+
| Liquor | Beer      | Wine |                 |
|        |           |      | That's showbiz! |
+--------+-----------+------+-----------------+%,
'rows and header row');

my $t1 = generate_table( rows => $rows, header_row => 1, indent => 2 );
is($t1, q%  +--------+-----------+------+-----------------+
  | Elvis  | Priscilla |      |                 |
  +--------+-----------+------+-----------------+
  | Liquor | Beer      | Wine |                 |
  |        |           |      | That's showbiz! |
  +--------+-----------+------+-----------------+%,
'rows and header row with indent');

my $t2 = generate_table( rows => $rows, separate_rows => 1 );
is($t2,q%+--------+-----------+------+-----------------+
| Elvis  | Priscilla |      |                 |
+--------+-----------+------+-----------------+
| Liquor | Beer      | Wine |                 |
+--------+-----------+------+-----------------+
|        |           |      | That's showbiz! |
+--------+-----------+------+-----------------+%,
'separate rows');

my $t3 = generate_table( rows => $rows, header_row => 1, separate_rows => 1 );
is($t3,q%+--------+-----------+------+-----------------+
| Elvis  | Priscilla |      |                 |
O========O===========O======O=================O
| Liquor | Beer      | Wine |                 |
+--------+-----------+------+-----------------+
|        |           |      | That's showbiz! |
+--------+-----------+------+-----------------+%,
'header and separate rows');
