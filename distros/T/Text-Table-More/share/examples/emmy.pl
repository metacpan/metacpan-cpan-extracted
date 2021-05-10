#!perl

use 5.010001;
use strict;
use warnings;

use Text::Table::More qw/generate_table/;

my $rows = [
    # header row
    ["Year",
     "Comedy",
     "Drama",
     "Variety",
     "Lead Comedy Actor",
     "Lead Drama Actor",
     "Lead Comedy Actress",
     "Lead Drama Actress"],

    # first data row
    [1962,
     "The Bob Newhart Show (NBC)",
     {text=>"The Defenders (CBS)", rowspan=>3}, # each cell can be hashref to specify text (content) as well as attributes
     "The Garry Moore Show (CBS)",
     {text=>"E. G. Marshall, The Defenders (CBS)", rowspan=>2, colspan=>2},
     {text=>"Shirley Booth, Hazel (NBC)", rowspan=>2, colspan=>2}],

    # second data row
    [1963,
     {text=>"The Dick Van Dyke Show (CBS)", rowspan=>2},
     "The Andy Williams Show (NBC)"],

    # third data row
    [1964,
     "The Danny Kaye Show (CBS)",
     {text=>"Dick Van Dyke, The Dick Van Dyke Show (CBS)", colspan=>2},
     {text=>"Mary Tyler Moore, The Dick Van Dyke Show (CBS)", colspan=>2}],

    # fourth data row
    [1965,
     {text=>"four winners (Outstanding Program Achievements in Entertainment)", colspan=>3},
     {text=>"five winners (Outstanding Program Achievements in Entertainment)", colspan=>4}],

    # fifth data row
    [1966,
     "The Dick Van Dyke Show (CBS)",
     "The Fugitive (ABC)",
     "The Andy Williams Show (NBC)",
     "Dick Van Dyke, The Dick Van Dyke Show (CBS)",
     "Bill Cosby, I Spy (CBS)",
     "Mary Tyler Moore, The Dick Van Dyke Show (CBS)",
     "Barbara Stanwyck, The Big Valley (CBS)"],
];

binmode STDOUT, "utf8";
print generate_table(
    rows => $rows,      # required
    header_row => 1,    # optional, default 0
    separate_rows => 1, # optional, default 0
    border_style => $ARGV[0] // 'ASCII::SingleLineDoubleAfterHeader', # optional, this is module name in BorderStyle::* namespace, without the prefix
    #align => 'left',   # optional, default 'left'. can be left/middle/right.
    #valign => 'top',   # optional, default 'top'. can be top/middle/bottom.
    #color => 1,        # optional, default 0. turn on support for cell content that contain ANSI color codes.
    #wide_char => 1,    # optional, default 0. turn on support for wide Unicode characters.

    row_attrs => [      # optional, specify per-row attributes
        # rownum (0-based int), attributes (hashref)
        [0, {align=>'middle', bottom_border=>1}],
    ],

    col_attrs => [      # optional, per-column attributes
        # colnum (0-based int), attributes (hashref)
        [2, {valign=>'middle'}],
    ],

    #cell_attrs => [    # optional, per-cell attributes
    #    # rownum (0-based int), colnum (0-based int), attributes (hashref)
    #    [1, 2, {rowspan=>3}],
    #    [1, 4, {rowspan=>2, colspan=>2}],
    #    [1, 5, {rowspan=>2, colspan=>2}],
    #    [2, 1, {rowspan=>2}],
    #    [3, 2, {colspan=>2}],
    #    [3, 3, {colspan=>2}],
    #    [4, 1, {colspan=>3}],
    #    [4, 2, {colspan=>4}],
    #],

);
