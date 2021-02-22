#!perl

use 5.010001;
use strict;
use warnings;

use Text::Table::Span qw(generate_table);

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
     {text=>"The Defenders (CBS)", rowspan=>3},
     "The Garry Moore Show (CBS)",
     {text=>"E. G. Marshall\nThe Defenders (CBS)", rowspan=>2, colspan=>2},
     {text=>"Shirley Booth\nHazel (NBC)", rowspan=>2, colspan=>2}],
    # second data row
    [1963,
     {text=>"The Dick Van Dyke Show (CBS)", rowspan=>2},
     "The Andy Williams Show (NBC)"],
    # third data row
    [1964,
     "The Danny Kaye Show (CBS)",
     {text=>"Dick Van Dyke\nThe Dick Van Dyke Show (CBS)", colspan=>2},
     {text=>"Mary Tyler Moore\nThe Dick Van Dyke Show (CBS)", colspan=>2}],
    # fourth data row
    [1965,
     {text=>"four winners", colspan=>3},
     {text=>"five winners", colspan=>4}],
    # fifth data row
    [1966,
     "The Dick Van Dyke Show (CBS)",
     "The Fugitive (ABC)",
     "The Andy Williams Show (NBC)",
     "Dick Van Dyke\nThe Dick Van Dyke Show (CBS)",
     "Bill Cosby\nI Spy (CBS)",
     "Mary Tyler Moore\nThe Dick Van Dyke Show (CBS)",
     "Barbara Stanwyck\nThe Big Valley (CBS)"],
];

binmode STDOUT, "utf8";
print generate_table(
    rows => $rows,
    #border_style => "UTF8::SingleLineBoldHeader",
    border_style => "ASCII::SingleLineDoubleAfterHeader",
    separate_rows => 1,
    header_row => 1,
);
