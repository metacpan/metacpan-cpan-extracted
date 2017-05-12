#!/usr/bin/perl

use strict;
use warnings;

use Tie::CSV_File;
use File::Temp qw/tmpnam/;

use constant OPTIONS => (
    [],  # should also work with defaults :-)
    [sep_char     => "|"],
    [quote_char   => q/%/],
    [eol          => q/EOL/],
    [escape_char  => q/&/],
    [always_quote => 1],
);

use Test::More tests => scalar(OPTIONS());

foreach (OPTIONS) {
    my $fname = tmpnam();
    tie my @file, 'Tie::CSV_File', $fname, @$_;

    $file[0][0] = "";
    is_deeply \@file, [ [""] ], qq/Set simple [ [""] ] array with options @$_/;

    untie @file;
}
