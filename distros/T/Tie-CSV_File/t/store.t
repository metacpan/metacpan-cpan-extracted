#!/usr/bin/perl

use strict;
use warnings;
use Tie::CSV_File;
use File::Temp qw/tmpnam/;
use Test::More;
use Test::Exception;
use t::CommonStuff;

sub test_store_cell($%) {
    my ($expected_csv_text, %option) = @_;
    my $csv_name = tmpnam();
    
    tie my @data, 'Tie::CSV_File', $csv_name, %option;
    foreach my $line_nr (0 .. scalar(@{CSV_DATA()})-1) {
        my @column = @{ CSV_DATA()->[$line_nr] };
        foreach my $col_nr (0 .. $#column) {
             $data[$line_nr][$col_nr] = $column[$col_nr];
        }
    }
    
    _compare_written_to_exp_content(
        \@data, $csv_name, \%option, "Store cell by cell"
    );
}

sub _compare_written_to_exp_content($$$$) {
    my ($tied_data, $fname, $options, $desc) = @_;

    open CSV, $fname or die "Could not open the csv file $fname: $!";
    my $file_before_untie = join "", (<CSV>);
    close CSV;
    is_deeply $tied_data, CSV_DATA(), "$desc, tied data is_deeply expected data"
    or diag "Expected (wrote $file_before_untie) of " . Dumper(CSV_DATA());
    
    untie @$tied_data;
    
    open CSV, $fname or die "Could not open the csv_file $fname: $!";
    my $file_after_untie = join "", (<CSV>);
    close CSV;
    
    is $file_before_untie, $file_after_untie,
       "$desc, Got content of file when data was tied, " .
       "Expected to be the same when untied";
       
    tie my @data, 'Tie::CSV_File', $fname, %$options;
    is_deeply \@data, CSV_DATA(),
              "$desc, untied, retied should be the same"
    or diag "Written CSV: $file_after_untie";
    untie @data;
}

sub test_store_line($%) {
    my ($expected_csv_text, %option) = @_;
    my $csv_name = tmpnam();
    
    tie my @data, 'Tie::CSV_File', $csv_name, %option;
    foreach (reverse (0 .. scalar(@{CSV_DATA()})-1)) {
        $data[$_] = CSV_DATA()->[$_];
    }
    
    _compare_written_to_exp_content(
        \@data, $csv_name, \%option, "Store line by line"
    ); 
}

use Test::More tests => 2 * 3 * scalar(CSV_FILES) + 11;

foreach (CSV_FILES) {
    my @option   = @{$_->[0]};
    my $csv_text = $_->[1];
    test_store_cell $csv_text, @option;
    test_store_line $csv_text, @option;
}

unlink 'csv.dat';
{
    tie my @data, 'Tie::CSV_File', 'csv.dat';
    is $data[2][2] = "(2,2)", "(2,2)", '$data[x][y] = z returns value of assignment';
    is_deeply \@data, [ [], [], ['', '', "(2,2)"] ],
          "Set a data element, but didn't set some elements before"
    or diag "Got completely: " . Dumper(\@data);
    untie @data;
}

{
    tie my @data, 'Tie::CSV_File', 'csv.dat';
    is_deeply \@data, [ [], [], ['', '', "(2,2)"] ],
          "Set a data element, but didn't set some elements before - after rereading";
    untie @data;
}

{
    tie my @data, 'Tie::CSV_File', 'csv.dat';
    $data[-1][-1] = "-(2,2)";
    is_deeply \@data, [ [], [], ['', '', "-(2,2)"] ],
          "Set a data element at last line, last column";
          
    is_deeply $data[10] = [1, 2, 3], [1, 2, 3], '$data[x] = [c1,c2,c3] returns value of assignment';
    
    foreach my $l (0, 20) {
        foreach my $val (undef, "something", {}) {
            dies_ok {$data[$l] = $val} 
                    '$data[x] = scalar instead of $data[x] = [c1,c2,c3]';
        }
    }

    untie @data;
}
unlink 'csv.dat';
