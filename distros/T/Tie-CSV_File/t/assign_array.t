#!/usr/bin/perl

use strict;
use warnings;

use Tie::CSV_File;
use t::CommonStuff;
use File::Temp qw/tmpnam/;

use Test::More tests => 2;

my $fname = tmpnam(); 
tie my @file, 'Tie::CSV_File', $fname;

@file = @{CSV_DATA()};

is_deeply 
    \@file, CSV_DATA(), 
    'Checked an assignment like @data = @anotherarray';

untie @file;

tie my @file_again, 'Tie::CSV_File', $fname;

is_deeply
    \@file_again, CSV_DATA(),
    'Checked an assignment like @data = @anotherarray (after rereading the file)';

untie @file_again;
