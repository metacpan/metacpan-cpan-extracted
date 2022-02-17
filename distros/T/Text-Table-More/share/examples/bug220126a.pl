#!perl

use 5.010001;
use strict;
use warnings;

use Text::Table::More qw/generate_table/;

my %table = (
    rows => [
        # header
        [{text=>'header1', rowspan=>4}, {text=>'header2',colspan=>2}, {text=>'header3', rowspan=>4}],
        ['header2a', 'header2b'],
        ['header2c', 'header2d'],
        [{text=>'header2e', colspan=>2}],
        # data
        [{text=>1, rowspan=>2},{text=>'2-3',colspan=>2},{text=>4,rowspan=>2}],
        [5,8],
    ],
    row_attrs => [
        [0, {align=>"middle", _valign=>"middle", bottom_border=>1}],
        [1, {align=>"middle", valign=>"middle", bottom_border=>1}],
    ],
    header_row => 1,
    separate_rows => 1,
);

binmode(STDOUT, ":utf8");
say "with header_row => 4 (OK):";
print generate_table(%table, header_row=>4);
say "with header_row => 1 (buggy):";
print generate_table(%table);
