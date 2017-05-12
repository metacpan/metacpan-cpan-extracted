#!/usr/bin/perl 

use strict;
use warnings;

use Tie::CSV_File;
use File::Temp qw/tmpnam/;
use t::CommonStuff;
use Test::More;
use Data::Compare;
use Data::Dumper;

sub test_delete_a_cell {
    my ($line, $nr) = @_;
    my $fname = tmpnam();
    my @data = ();
    push @data, [ @$_ ] for @{CSV_DATA()};
    tie my @file, 'Tie::CSV_File', $fname;
    push @file, [ @$_  ] for @{CSV_DATA()};
    
    Compare(\@file, \@data) or fail "No deep copy of CSV_DATA ($line, $nr)";

    delete $file[$line][$nr];
    
    ok !Compare(\@file, \@data), 
       "delete \$file[$line][$nr], expected differences when comparing"
    or diag "Tied File: " . Dumper(\@file) . "\n",
            "CSV Data: " . Dumper(\@data) . "\n";          
       
    $data[$line][$nr] = "";
    
    is_deeply \@file, \@data,
              "Deletion of \$file[$line][$nr] should be the same as deleting in normal array";

    untie @file;
    tie my @file2, 'Tie::CSV_File', $fname;
    
    is_deeply \@file2, \@data,
              "Deletion of \$file[$line][$nr] after untieing";
    untie @file2;
}

sub test_delete_a_line {
    my $line = shift;
    my $fname = tmpnam();
    my @data = ();
    push @data, [ @$_ ] for @{CSV_DATA()};
    tie my @file, 'Tie::CSV_File', $fname;
    push @file, [ @$_  ] for @{CSV_DATA()};
    
    Compare(\@file, \@data) or fail "No deep copy of CSV_DATA ($line)";

    delete $file[$line];    
    ok !Compare(\@file, \@data), 
       "delete \$file[$line], expected differences when comparing"
    or diag "Tied File: " . Dumper(\@file) . "\n",
            "CSV Data: " . Dumper(\@data) . "\n";          
       
    $data[$line] = [];
    
    is_deeply \@file, \@data,
              "Deletion of \$file[$line] should be the same as deleting in normal array";

    untie @file;
    tie my @file2, 'Tie::CSV_File', $fname;
    
    is_deeply \@file2, \@data,
              "Deletion of \$file[$line] after untieing";
    untie @file2;
}

use Test::More tests => 60;

my @csv_data = @{CSV_DATA()};
foreach my $line (0 .. $#csv_data) {
    my @csv_line = @{$csv_data[$line]};
    test_delete_a_line($line) if @{$csv_data[$line]};
    foreach my $col (0 .. $#csv_line) {
        test_delete_a_cell($line,$col) if $csv_data[$line][$col];
    }
}
