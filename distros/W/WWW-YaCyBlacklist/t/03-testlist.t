#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 49;

require_ok( 'WWW::YaCyBlacklist' );

my $ycb = WWW::YaCyBlacklist->new( { 'use_regex' => 1 } );
$ycb->read_from_array(
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
    'test17.co/^fullpath$',
);
is( $ycb->check_url( 'http://test1.co/fullpath' ), 1, 'match0' );
is( $ycb->check_url( 'http://sub.test1.co/fullpath' ), 1, 'match1' );
is( $ycb->check_url( 'http://test2.co/fullpath' ), 1, 'match2' );
is( $ycb->check_url( 'http://sub.test2.co/fullpath' ), 1, 'match3' );
is( $ycb->check_url( 'http://sub.sub.sub.test2.co/fullpath' ), 1, 'match4' );
is( $ycb->check_url( 'http://sub.test3.co/fullpath' ), 1, 'match5' );
is( $ycb->check_url( 'http://sub.sub.test3.co/fullpath' ), 1, 'match6' );
is( $ycb->check_url( 'http://sub.sub.sub.test3.co/fullpath' ), 1, 'match7' );
is( $ycb->check_url( 'http://sub.sub.test4.co/fullpath' ), 1, 'match8' );
is( $ycb->check_url( 'http://sub.sub.sub.test4.co/fullpath' ), 1, 'match9' );
is( $ycb->check_url( 'http://sub.test5.co/fullpath' ), 1, 'match10' );
is( $ycb->check_url( 'http://test6.co/fullpath' ), 1, 'match11' );
is( $ycb->check_url( 'http://regexptest7.co/fullpath.html' ), 1, 'match12' );
is( $ycb->check_url( 'http://test8.co/fullpath.htm' ), 1, 'match13' );
is( $ycb->check_url( 'http://sub.test8.co/fullpath.htm' ), 1, 'match14' );
is( $ycb->check_url( 'http://test9.co/%C3%A4%C3%B6%C3%BC%C3%9F%C3%84%C3%96%C3%9C' ), 1, 'match15' );
is( $ycb->check_url( 'http://sub.test9.co/%C3%A4%C3%B6%C3%BC%C3%9F%C3%84%C3%96%C3%9C' ), 1, 'match16' );
is( $ycb->check_url( 'http://test10.co/fullpath.-_' ), 1, 'match17' );
is( $ycb->check_url( 'http://sub.test10.co/fullpath.-_' ), 1, 'match18' );
is( $ycb->check_url( 'http://test11.co/fullpath-_' ), 1, 'match19' );
is( $ycb->check_url( 'http://sub.test11.co/fullpath-_' ), 1, 'match20' );
is( $ycb->check_url( 'http://test12.co/fullpath-' ), 1, 'match21' );
is( $ycb->check_url( 'http://sub.test12.co/fullpath-' ), 1, 'match22' );
is( $ycb->check_url( 'http://test13.co/fullpath1234567890' ), 1, 'match23' );
is( $ycb->check_url( 'http://sub.test13.co/fullpath1234567890' ), 1, 'match24' );
is( $ycb->check_url( 'http://test1.co/fullpatha' ), 0, 'nonmatch0' );
is( $ycb->check_url( 'http://test1.co/afullpath' ), 0, 'nonmatch1' );
is( $ycb->check_url( 'http://sub.test1.co/fullpatha' ), 0, 'nonmatch2' );
is( $ycb->check_url( 'http://sub.test1.co/afullpath' ), 0, 'nonmatch3' );
is( $ycb->check_url( 'http://test14.co/fullpath' ), 0, 'nonmatch4' );
is( $ycb->check_url( 'http://sub.test14.co/fullpath' ), 0, 'nonmatch5' );
is( $ycb->check_url( 'http://test14.co/fullpath?ref=test' ), 0, 'nonmatch6' );
is( $ycb->check_url( 'http://sub.test14.co/fullpath?ref=test' ), 0, 'nonmatch7' );
is( $ycb->check_url( 'http://test1.co/fullpath?ref=test' ), 0, 'nonmatch8' );
is( $ycb->check_url( 'http://sub.test1.co/?ref=test' ), 0, 'nonmatch9' );
is( $ycb->check_url( 'http://test6.co/fullpath?ref=test' ), 1, 'match25' );
is( $ycb->check_url( 'http://sub.test6.co/fullpath?ref=test' ), 0, 'nonmatch10' );
is( $ycb->check_url( 'http://test15.co/fullpath?ref=test' ), 1, 'match26' );
is( $ycb->check_url( 'http://sub.test15.co/fullpath?ref=test' ), 1, 'match27' );
is( $ycb->check_url( 'http://sub.test16.co/fullpath' ), 1, 'match28' );
is( $ycb->check_url( 'http://sub.sub.test16.co/fullpath' ), 1, 'match29' );
is( $ycb->check_url( 'http://sub.sub.sub.test16.co/fullpath' ), 1, 'match30' );
is( $ycb->check_url( 'http://test17.co/fullpath' ), 1, 'match31' );
is( $ycb->check_url( 'http://sub.test17.co/fullpath' ), 1, 'match32' );
is( $ycb->check_url( 'http://sub.sub.test17.co/fullpath' ), 1, 'match33' );

my @m = (
    # matches
    'http://test1.co/fullpath',
    'http://sub.sub.test17.co/fullpath',
    'http://test6.co/fullpath',
    'http://sub.sub.test3.co/fullpath',
    'http://test9.co/%C3%A4%C3%B6%C3%BC%C3%9F%C3%84%C3%96%C3%9C',

    # non-matches
    'http://sub.test1.co/fullpatha',
    'http://sub.test6.co/fullpath?ref=test',
);

is( scalar $ycb->find_matches( @m ), 5, 'arraymatches' );
is( scalar $ycb->find_non_matches( @m ), 2, 'array non-matches' );

$ycb->delete_pattern( 'test9.co/%C3%A4%C3%B6%C3%BC%C3%9F%C3%84%C3%96%C3%9C' );
is( scalar $ycb->find_matches( @m ), 4, 'deleted pattern' );

$ycb->sorting('length');
$ycb->filename('C:\Users\Work\Documents\ingram\Perl\a.black');
#$ycb->store_list();