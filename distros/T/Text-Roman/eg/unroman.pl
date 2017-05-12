#!/usr/bin/env perl
use strict;
use warnings qw(all);

use Text::Roman qw(ismilhar milhar2int);

# Filter text, replacing Roman numerals by Arabic equivalent

while (<>) {
    my $n;
    s/
        \b
        ([IVXLCDM_]{2,})
        \b
    /
        (
            ismilhar($1)
            and defined($n = milhar2int($1))
        ) ? $n : $1
    /egix;

    print;
}
