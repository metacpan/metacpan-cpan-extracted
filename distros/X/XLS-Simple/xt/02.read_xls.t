#!/usr/bin/perl
use XLS::Simple;
use Test::More;
use Data::Dumper;
use Encode;
use Encode::Locale;

my $header = read_xls( 'test.xlsx', only_header => 1, );
my $data = read_xls( 'test.xlsx', skip_header => 1, );
my $all = read_xls( 'test.xlsx', );

print encode( locale => decode( "utf8", Dumper( $header, $data, $all ) ) );

done_testing;
