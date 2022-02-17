#!perl

use strict;
use warnings;

use Text::Table::TinyBorderStyle qw(generate_table);

binmode(STDOUT, ":encoding(utf8)");
print generate_table(
    rows => [ [qw/col1 col2 col3/], [1,2,3], [4,5,6], [7,8,9] ],
    header_row => 1,
    separate_rows => 1,
), "\n";
