#!/usr/bin/perl

use strict;
use warnings;
use Tie::CSV_File;
use File::Temp qw/tempfile tmpnam/;
use Test::More;
use t::CommonStuff;

sub test_option($%) {
    my ($expected_csv_text, $data, %option) = @_;
    my ($csv_fh,$csv_name) = tempfile();
    print $csv_fh $expected_csv_text;
    close $csv_fh;

    tie my @data, 'Tie::CSV_File', $csv_name, %option;
    is_deeply \@data, $data,
              "tied file eq_array to csv_data with options " . Dumper(\%option);
    untie @data;
}


use Test::More tests => scalar(CSV_FILES) + 8;

foreach (CSV_FILES) {
    my @option   = @{$_->[0]};
    my $csv_text = $_->[1];
    test_option $csv_text, CSV_DATA(), @option;
}

test_option CSV_FILE_TAB_SEPARATED, CSV_DATA(), 
            TAB_SEPARATED;
test_option CSV_FILE_COLON_SEPARATED, CSV_DATA(),
            COLON_SEPARATED;            
test_option SIMPLE_CSV_FILE_WHITESPACE_SEPARATED, SIMPLE_CSV_DATA(), 
            WHITESPACE_SEPARATED;
{   
    local $SIG{__WARN__} = sub { };
    test_option SIMPLE_CSV_FILE_WHITESPACE_SEPARATED, SIMPLE_CSV_DATA(),
            WHITESPACE_SEPARATED, sep_char => '   ';            
    # the three whitespaces as sep_char should produce a warning,
    # but the result must still be O.K.
}
test_option SIMPLE_CSV_FILE_COLON_SEPARATED, SIMPLE_CSV_DATA(), 
            COLON_SEPARATED;
test_option SIMPLE_CSV_FILE_SEMICOLON_SEPARATED, SIMPLE_CSV_DATA(),
            SEMICOLON_SEPARATED;
test_option SIMPLE_CSV_FILE_PIPE_SEPARATED, SIMPLE_CSV_DATA(),
            PIPE_SEPARATED;

sub _written_content(@) {
    my $file = tmpnam();
    tie my @data, 'Tie::CSV_File', $file, @_;
    push @data, $_ for @{SIMPLE_CSV_DATA()};
    untie @data;
    open CSV, $file or die "Can't open CSV file $file: $!";
    my $content = join "", (<CSV>);
    close CSV;
    return $content;
}   

my $c1 = _written_content WHITESPACE_SEPARATED;
my $c2 = _written_content WHITESPACE_SEPARATED, sep_char => "\t";

$c1 =~ s/ /\t/gs;
is $c1, $c2, 
   "Changing the sep_char of WHITESPACE_SEPARATED should change the written content";
