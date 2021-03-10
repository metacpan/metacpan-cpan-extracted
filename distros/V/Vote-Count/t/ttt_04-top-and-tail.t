use strict;
use Test::More tests => 4;
use Vote::Count::TextTableTiny qw/ generate_table /;

my $rows = [
   [ 'Elvis', 'Priscilla' ],
   [ 'Liquor', 'Beer', 'Wine' ],
   [ undef, undef, undef, "That's showbiz!" ],
   [ 'Banana', 'Cherry', undef, "Tomato" ],
];

my $t0 = generate_table( rows => $rows, top_and_tail => 1 );
is($t0, q%| Elvis  | Priscilla |      |                 |
| Liquor | Beer      | Wine |                 |
|        |           |      | That's showbiz! |
| Banana | Cherry    |      | Tomato          |%,
"top and bottom rules should be missing"
);


my $t1 = generate_table( rows => $rows, top_and_tail => 1, header_row => 1, separate_rows => 1 );
is($t1, q%| Elvis  | Priscilla |      |                 |
O========O===========O======O=================O
| Liquor | Beer      | Wine |                 |
+--------+-----------+------+-----------------+
|        |           |      | That's showbiz! |
+--------+-----------+------+-----------------+
| Banana | Cherry    |      | Tomato          |%,
"ornate table, but top and bottom rules should be missing"
);

pop(@$rows);
pop(@$rows);

my $t0 = generate_table( rows => $rows, top_and_tail => 1 );
is($t0, q%| Elvis  | Priscilla |      |
| Liquor | Beer      | Wine |%,
"top and bottom rules should be missing"
);


my $t1 = generate_table( rows => $rows, top_and_tail => 1, header_row => 1, separate_rows => 1 );
is($t1, q%| Elvis  | Priscilla |      |
O========O===========O======O
| Liquor | Beer      | Wine |%,
"ornate table, but top and bottom rules should be missing"
);
