use strict;
use Test::More tests => 1;
use Vote::Count::TextTableTiny qw/ generate_table /;
use utf8;

my $rows = [
   ["Hello"],
   ["😄"],
   ["こんにちは"],
];
my $table;


$table = generate_table( rows => $rows, header_row => 0, style => 'boxrule', align => 'left' );
is($table, q%┌────────────┐
│ Hello      │
│ 😄         │
│ こんにちは │
└────────────┘%,
"wide emoji and wide hiragana"
);

