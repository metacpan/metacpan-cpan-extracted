#!perl

use 5.010001;
use strict;
use warnings;

use Text::Table::More qw/generate_table/;

my %table1 = (
    rows => [
        [{text=>'colspan=2,rowspan=3', colspan=>2, rowspan=>3}, {text=>'cell'}, {text=>'cell'}],
        [{text=>'cell'}, {text=>'cell'}],
        [{text=>'colspan=2,rowspan=2', colspan=>2, rowspan=>2}],
        [{text=>'cell',tpad=>2}, {text=>'cell'}],
    ],
    separate_rows => 1,
    align => 'middle',
    valign => 'middle',
    lpad => 0,
    rpad => 0,
    tpad=>0,
    bpad=>0,
    #pad_char=>'x',
);

binmode(STDOUT, ":utf8");
say "Set BORDER_STYLE environment to see different border style, e.g. UTF8::SingleLineBold";
print generate_table(%table1, border_style => $ENV{BORDER_STYLE} // "UTF8::SingleLineBold");
