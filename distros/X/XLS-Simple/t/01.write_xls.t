#!/usr/bin/perl
use XLS::Simple;
use Test::More ;
use Data::Dumper;
use Encode;
use Encode::Locale;


write_xls([ ['测试', '写入' ] ], 
    'test.xlsx', 
    header=> ['一二', '三四'], 
    charset=>'utf8');

my $header = read_xls( 'test.xlsx', only_header => 1, );
my $data = read_xls( 'test.xlsx', skip_header => 1, );
my $all = read_xls( 'test.xlsx', );

#print encode( locale => decode( "utf8", Dumper( $header, $data, $all ) ) );

is($header->[0], '一二');
is($data->[0][0], '测试');
is($all->[0][0], '一二');
is($all->[1][0], '测试');


done_testing;
