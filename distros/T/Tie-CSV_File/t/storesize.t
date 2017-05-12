#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw/no_plan/;
use Tie::CSV_File;
use File::Temp qw/tmpnam/;
use t::CommonStuff;

my $fname = tmpnam();
tie my @file, 'Tie::CSV_File', $fname;

$#file = 9;
is scalar(@file),10,"Set the size (number of lines) to 10";
is_deeply \@file, [([]) x 10 ], "Should be ten empty lines";

$#file = -1;
is scalar(@file),0,"Reset the size (number of lines) to 0";
is_deeply \@file, [], "Should be really empty";

$#file = 9;
$#{$file[-1]} = 4;
is scalar(@{$file[-1]}),5,"Set 10 lines, last consisting of 5 columns";
is_deeply 
    \@file, [ ([]) x 9, ["", "", "", "", ""] ], 
    "Should be 4 empty rows + 1 of 5 columns";

$#{$file[-1]} = 0;
is scalar(@{$file[-1]}),1,"Set 10 lines, last consisting of 1 columns";
is_deeply 
    \@file, [ ([]) x 9, [""] ], 
    "Should be 4 empty rows + 1 of 5 columns";

$#{$file[-1]} = -1;
is scalar(@{$file[-1]}),0,"Reset last row to zero columns";
is_deeply
    \@file, [ ([]) x 9 ],
    "Should be 5 empty rows";
