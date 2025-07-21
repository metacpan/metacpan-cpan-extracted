#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 3;
use WWW::YaCyBlacklist;

my $file = 'C:/Users/Work/Documents/ingram/Perl/dzil/WWW-YaCyBlacklist/xt/ycb.black';
my @urls = (
    'test1.co/fullpath',
    'test2.co/.*',
    '*.test3.co/.*',
    '*.sub.test4.co/.*',
    'sub.test5.*/.*',
    'test6.*/.*',
    '(regexp)test7\.\w+/[a-z]+\.\w{1,5}',
    'test8.co/[a-z]+\.htm',
    'test9.co/%C3%A4%C3%B6%C3%BC%C3%9F%C3%84%C3%96%C3%9C',
    'test10.co/fullpath.-_',
    'test11.co/fullpath-_',
    'test12.co/fullpath-',
    'test13.co/fullpath1234567890',
    'test14.co/fullpath?ref=test',
    'test15.co/fullpath\?ref=test',
    'sub.test16.co/.*',
    'test17.co/fullpath$',
);

my $ycb = WWW::YaCyBlacklist->new( { 'use_regex' => 1 } );
$ycb->read_from_array( @urls );
$ycb->filename( $file );
$ycb->store_list( );

my $ybl = WWW::YaCyBlacklist->new( { 'use_regex' => 0 } );
$ybl->read_from_files( $file );

cmp_ok( $ycb->length( ), '==', scalar @urls, 'length_ycb' );
cmp_ok( $ybl->length( ), '==', scalar @urls, 'length_ybl' );
cmp_ok( $ycb->length( ), '==',  $ybl->length( ), 'length_diff' );
