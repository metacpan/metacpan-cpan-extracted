#!/usr/bin/perl 

use strict;
use warnings;
use File::Temp qw/tempfile tmpnam/;
use t'CommonStuff;

my ($csv_fh,$csv_name) = tempfile();
print $csv_fh CSV_FILE;
close $csv_fh;
END {
    unlink $csv_name;
}

use Test::More tests => 5;

use Tie::CSV_File;

tie my @data, 'Tie::CSV_File', $csv_name;
is_deeply \@data, CSV_DATA(), "tied file eq_array to csv_data";

is $data[-1][-1], CSV_DATA()->[-1]->[-1] , "last element in last row";
is $data[1_000][0], undef, "non existing element in the 1000th line";
is $data[0][1_000], undef, "non existing element in the 1000th column";

tie my @empty, 'Tie::CSV_File', scalar(tmpnam());
is_deeply \@empty, [], "tied empty file";
