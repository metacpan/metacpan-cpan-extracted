#!perl

use 5.010001;
use strict;
use warnings;

use Text::Table::More qw/generate_table/;

my %table = (
    rows => [
        ['col1', 'col2', 'col3'],
        [1,2,3],
        [4,5,6],
        [7,8,9],
        [10,11,12],
    ],
    #separate_rows => 1,
    header_row => 1,
);

binmode(STDOUT, ":utf8");
print generate_table(%table);
