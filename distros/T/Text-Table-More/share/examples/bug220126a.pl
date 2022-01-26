#!perl

use 5.010001;
use strict;
use warnings;

use Text::Table::More qw/generate_table/;

print generate_table(
    rows => [
        # header
        [{text=>'header1', rowspan=>2}, {text=>'header2',colspan=>2}, {text=>'header3', rowspan=>2}],
        ['header2a', 'header2b'],
        # data
        [{text=>1, rowspan=>2},{text=>'2-3',colspan=>2},{text=>4,rowspan=>2}],
        [5,8],
    ],
    row_attrs => [
        [0, {align=>"middle", _valign=>"middle", bottom_border=>1}],
        [1, {align=>"middle", valign=>"middle", bottom_border=>1}],
    ],
    header_row => 1,
    #border_style => "UTF8::SingleLineDoubleAfterHeader",
    #border_style => "Test::Labeled",
    separate_rows => 1,
);
