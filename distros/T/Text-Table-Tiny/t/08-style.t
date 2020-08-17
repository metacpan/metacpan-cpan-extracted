use strict;
use Test::More tests => 3;
use Text::Table::Tiny qw/ generate_table /;
use utf8;

my $rows = [
   [ 'Pokemon', 'Type', 'Seen' ],
   [ 'Rattata', 'Normal', 10199 ],
   [ 'Ekans', 'Poison', 536 ],
   [ 'Vileplume', 'Grass / Poison', 4 ],
];
my $table;

$table = generate_table( rows => $rows, header_row => 1, style => 'classic', align => 'left' );
is($table, q%+-----------+----------------+-------+
| Pokemon   | Type           | Seen  |
+-----------+----------------+-------+
| Rattata   | Normal         | 10199 |
| Ekans     | Poison         | 536   |
| Vileplume | Grass / Poison | 4     |
+-----------+----------------+-------+%,
"left, center, and right alignment"
);


$table = generate_table( rows => $rows, header_row => 1, style => 'boxrule', align => 'left' );
is($table, q%┌───────────┬────────────────┬───────┐
│ Pokemon   │ Type           │ Seen  │
├───────────┼────────────────┼───────┤
│ Rattata   │ Normal         │ 10199 │
│ Ekans     │ Poison         │ 536   │
│ Vileplume │ Grass / Poison │ 4     │
└───────────┴────────────────┴───────┘%,
"left, center, and right alignment"
);

$table = generate_table( rows => $rows, header_row => 1, style => 'norule', align => 'left' );
is($table, q%                                      
  Pokemon     Type             Seen   
                                      
  Rattata     Normal           10199  
  Ekans       Poison           536    
  Vileplume   Grass / Poison   4      
                                      %,
"left, center, and right alignment"
);
