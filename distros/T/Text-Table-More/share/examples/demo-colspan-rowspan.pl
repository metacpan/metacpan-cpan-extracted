#!perl

use 5.010001;
use strict;
use warnings;

use Text::Table::More qw/generate_table/;

my %table = (
    rows => [
        [{text=>'demo colspan', colspan=>4, align=>"middle"}],
        [{text=>'R1C1'}, {text=>'R1C2'}, {text=>'R1C3-4',colspan=>2}],
        [{text=>'R2C1'}, {text=>'R2C2'}, {text=>'R2C3-4',colspan=>2}],
        [{text=>'R3C1-2',colspan=>2}, {text=>'R3C3'}, {text=>'R3C4'}],
        [{text=>'R4C1-2',colspan=>2}, {text=>'R4C3'}, {text=>'R4C4'}],

        [{text=>'demo rowspan', colspan=>4, align=>"middle"}],
        [{text=>'R5-6C1-2',colspan=>2, rowspan=>2}, {text=>'R5C3-4',colspan=>2}],
        [{text=>'R6-7C3-4',colspan=>2, rowspan=>2}],
        [{text=>'R8C1-2',colspan=>2}],
    ],
    separate_rows => 1,
);

binmode(STDOUT, ":utf8");
say "with header_row => 0:";
say generate_table(%table, header_row=>0);

say "with header_row => 1:";
say generate_table(%table, header_row=>1);

say "with header_row => 7 (BUGGY):";
say generate_table(%table, header_row=>7);

say "with header_row => 8 (BUGGY):";
say generate_table(%table, header_row=>8);
