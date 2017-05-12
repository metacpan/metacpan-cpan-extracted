#!/usr/bin/perl

use strict;
use warnings;

use Tie::CSV_File;
use File::Temp qw/tmpnam/;
use t::CommonStuff;

use constant OPTIONS => (
    [sep_char    => '0'],
    [quote_char  => '0'],
    [eol         => '0'],
    [eol         => '00'],
    [eol         => '0.0'],
    [escape_char => 0],
);

use Test::More qw/no_plan/;

foreach (OPTIONS) {
    my $fname = tmpnam();
    tie my @file, 'Tie::CSV_File', $fname, @$_;
    push @file, $_ foreach @{SIMPLE_CSV_DATA()};
    
    is_deeply \@file, SIMPLE_CSV_DATA, "Set the options @$_";

    untie @file;
}
