#!/usr/bin/perl
use XLS::Simple;
use Test::More ;
use Data::Dumper;

write_xls([ ['测试', '写入' ] ], 
    'test.xlsx', 
    header=> ['一二', '三四'], 
    charset=>'utf8');

done_testing;
