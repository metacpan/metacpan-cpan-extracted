#!perl

use 5.010001;
use strict;
use warnings;

use Text::Table::More qw/generate_table/;

my %table = (
    rows => [
        ['A'],
    ],
    #separate_rows => 1,
    align => 'middle',
    valign => 'middle',
    lpad => 0,
    rpad => 0,
    #tpad=>0,
    #bpad=>0,
    #pad_char=>'x',
);

binmode(STDOUT, ":utf8");
print generate_table(%table);
