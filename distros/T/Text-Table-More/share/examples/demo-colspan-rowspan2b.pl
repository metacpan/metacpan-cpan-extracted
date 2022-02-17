#!perl

use 5.010001;
use strict;
use warnings;

use Text::Table::More qw/generate_table/;

my %table1 = (
    rows => [
        [{text=>".....\n.....\n.....\n.....\n.....", colspan=>2, rowspan=>3}, {text=>'.'}, {text=>'.'}],
        [{text=>'.'}, {text=>'.'}],
        [{text=>".....\n.....\n.....", colspan=>2, rowspan=>2}],
        [{text=>'.',tpad=>2}, {text=>'.'}],
    ],
    separate_rows => 1,
    align => 'middle',
    valign => 'middle',
    lpad => 1,
    rpad => 2,
    #tpad=>0,
    #bpad=>0,
    #pad_char=>'x',

    header_row=>2,
);

binmode(STDOUT, ":utf8");
say "Set BORDER_STYLE environment to see different border style, e.g. UTF8::SingleLineBold";
print generate_table(%table1, border_style => $ENV{BORDER_STYLE} // "UTF8::SingleLineBold");
