use strict;
use Test::More tests => 1;
use Vote::Count::TextTableTiny qw/ generate_table /;

my $bold      = "\e[1m";
my $reset     = "\e[0m";
my $underline = "\e[4m";

my $rows = [
   [ 'Pokemon',   'Type',           'Seen' ],
   [ 'Rattata',   "${bold}Normal${reset}",         10199 ],
   [ 'Ekans',     "${underline}Poison${reset}",         536 ],
   [ 'Vileplume', 'Grass / Poison', 4 ],
];
my $table;

$table = generate_table( rows => $rows, header_row => 1, style => 'classic', align => [qw/ l c r /] );
is($table, qq%+-----------+----------------+-------+
| Pokemon   |      Type      |  Seen |
+-----------+----------------+-------+
| Rattata   |     ${bold}Normal${reset}     | 10199 |
| Ekans     |     ${underline}Poison${reset}     |   536 |
| Vileplume | Grass / Poison |     4 |
+-----------+----------------+-------+%,
"left, center, and right alignment"
);

