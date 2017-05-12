#! /usr/bin/perl

use strict;
use warnings;

use Test::More tests => 35;
use FindBin;
use Encode qw/decode decode_utf8 is_utf8 encode_utf8/;
use IO::File;
use utf8;

BEGIN {
    use_ok('WWW::Analytics::MultiTouch::Tabular');
}

my @reports = (
	       {
		   title => 'Test 1 Title',
		   sheetname => 'Test 1 Sheetname',
		   headings => [ qw/A B C/ ],
		   data => [
			    [ 1, 2, 3 ],
			    [ 4, 5, 6 ],
			    [ 7, 8, 9 ],
			    ],
		   },

	       {
		   title => 'Test 2 Title',
		   sheetname => 'Test 2 Sheetname',
		   headings => [ qw/D E F/ ],
		   data => [
			    [ 11, 12, 13 ],
			    [ 14, 15, "http://acme.com/日本語" ],
			    [ 17, 18, "日本語"],
			    ],
               },
	       );

if ($^V lt v5.16.0) {
    for my $r (@reports) {
        for my $row (@{$r->{data}}) {
	    $_ = decode_utf8($_) for @$row;
        }
    }
}
my $dir = $FindBin::Bin;
my $tab = WWW::Analytics::MultiTouch::Tabular->new({ format => 'txt', filename => "$dir/txt-test.txt" });
ok($tab, "new txt");
$tab->print(\@reports);
$tab->close;

ok(0 == cmp_files("$dir/txt-test.txt", "$dir/txt-expected.txt"), "txt");


$tab->format('csv');
is($tab->format, 'csv', 'format');
$tab->filename("$dir/csv-test.csv");
is($tab->filename, "$dir/csv-test.csv", 'filename');
$tab->open;
$tab->print(\@reports);
$tab->close;

ok(0 == cmp_files("$dir/csv-test.csv", "$dir/csv-expected.csv"), "csv");

SKIP: {
    eval { require Spreadsheet::ParseExcel; };
    skip "Spreadsheet::ParseExcel not installed", 29 if $@;

    $tab->open("xls", "$dir/xls-test.xls");
    $tab->print(\@reports);
    $tab->close;

    my $fh = IO::File->new("$dir/xls-test.xls");
    binmode $fh, ':raw';
    my $excel = Spreadsheet::ParseExcel::Workbook->Parse($fh);
    close $fh;
    my @worksheets = @{$excel->{Worksheet}};
    ok(@worksheets == @reports, "excel worksheet count");

    for (0 .. @worksheets - 1) {
	is($worksheets[$_]->{Name}, $reports[$_]->{sheetname}, "excel sheet $_ name");
	is($worksheets[$_]->{Cells}[$worksheets[$_]->{MinRow}][0]->{Val}, $reports[$_]->{title}, "excel sheet $_ title");
	for my $j (0 .. @{$reports[$_]->{headings}}-1) {
	    is($worksheets[$_]->{Cells}[$worksheets[$_]->{MinRow} + 1][$j]->{Val}, $reports[$_]->{headings}->[$j], "excel sheet $_ header $j");
	}
	for my $i (0 .. @{$reports[$_]->{data}}-1) {
	    for my $j (0 .. @{$reports[$_]->{data}->[$i]}-1) {
		my $cell = $worksheets[$_]->{Cells}[$worksheets[$_]->{MinRow} + 2 + $i][$j];
		my $val = $cell->{Code} ? decode($cell->{Code}, $cell->{Val}) : $cell->{Val};
		is($val,
		   $reports[$_]->{data}->[$i]->[$j], "excel sheet $_ row $i col $j value");
	    }
	}
    }

    my @data = ([ 'Pie 1', 20 ],
                [ 'Pie 2', 50 ],
                [ 'Pie 3', 30 ]);
    
    my @reports2 = (
        {
            title => 'Test 3 Title',
            sheetname => 'Test 3 Sheetname',
            headings => [ qw/D E F/ ],
            data => \@data,
            chart => [ { type => 'pie',
                         title => { 
                                    name_formula => [0, 0],
                         },
                         abs_row => 0,
                         abs_col => 8,
                         x_scale => 1,
                         y_scale => 1,
                         series => [ 
                             { categories => [ 1, 3, 0, 0 ],
                               values => [ 1, 3, 1, 1 ],
                               name_formula => [1, 0],
                             } ],
                       } ],

        });

    $tab->open("xls", "$dir/xls-test2.xls");
    $tab->print(\@reports2);
    $tab->close;


}

sub cmp_files {
    my ($f1, $f2) = @_;

    open my $fh1, '<', $f1 or die "Failed to open $f1: $!";
    open my $fh2, '<', $f2 or die "Failed to open $f2: $!";
    my @lines1 = map { chomp } <$fh1>;
    my @lines2 = map { chomp } <$fh2>;
    close($fh1);
    close($fh2);
    return -1 if @lines1 != @lines2;
    for my $i (0 .. @lines1 - 1) {
	return -1 if $lines1[$i] ne $lines2[$i];
    }
    return 0;
}

