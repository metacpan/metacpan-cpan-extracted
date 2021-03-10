use strict;
use Test::More tests => 3;
use Vote::Count::TextTableTiny qw/ generate_table /;

my $rows = [
   [ 'Pokemon', 'Type', 'Seen' ],
   [ 'Rattata', 'Normal', 10199 ],
   [ 'Ekans', 'Poison', 536 ],
   [ 'Vileplume', 'Grass / Poison', 4 ],
];
my $table;

$table = generate_table( rows => $rows, header_row => 1, style => 'classic', align => [qw/ l c r /] );
is($table, q%+-----------+----------------+-------+
| Pokemon   |      Type      |  Seen |
+-----------+----------------+-------+
| Rattata   |     Normal     | 10199 |
| Ekans     |     Poison     |   536 |
| Vileplume | Grass / Poison |     4 |
+-----------+----------------+-------+%,
"left, center, and right alignment"
);


$table = generate_table( rows => $rows, header_row => 1, style => 'classic', align => [qw/ left center right /] );
is($table, q%+-----------+----------------+-------+
| Pokemon   |      Type      |  Seen |
+-----------+----------------+-------+
| Rattata   |     Normal     | 10199 |
| Ekans     |     Poison     |   536 |
| Vileplume | Grass / Poison |     4 |
+-----------+----------------+-------+%,
"left, center, and right alignment"
);

$table = generate_table( rows => $rows, header_row => 1, style => 'classic', align => 'center' );
is($table, q%+-----------+----------------+-------+
|  Pokemon  |      Type      | Seen  |
+-----------+----------------+-------+
|  Rattata  |     Normal     | 10199 |
|   Ekans   |     Poison     |  536  |
| Vileplume | Grass / Poison |   4   |
+-----------+----------------+-------+%,
"single alignment for all columns"
);

