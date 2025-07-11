#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 8;

require_ok( 'WWW::YaCyBlacklist' );

my $ycb = WWW::YaCyBlacklist->new( { 'use_regex' => 1 } );
is( $ycb->_check_host_regex('*.today'), 0, 'domain' );
is( $ycb->_check_host_regex('fritz.box'), 0, 'host' );
is( $ycb->_check_host_regex('\bhsk\d+.*\.\w/.*'), 1, 'regex' );

my $length = $ycb->length;
is( $length, 0, 'no_files' );
$ycb->read_from_array('research.ingram-braun.net/.*','wpdev.ingram-braun.net/.*','links.ingram-braun.net/.*' );
cmp_ok( $ycb->length, '>', $length, 'numerical' );
like( $ycb->length, '/\d{1}/', 'read_from_array' );

my $black1 = 'C:/Users/Work/Documents/ingram/Perl/dzil/WWW-YaCyBlacklist/yacy/default.black';
my $black2 = "C:/Users/Work/Documents/ingram/Perl/dzil/WWW-YaCyBlacklist/yacy/ib-mirrors.black";
$ycb = WWW::YaCyBlacklist->new( { 'use_regex' => 1 } );
$ycb->read_from_files($black1,$black2);
like( $ycb->length, '/\d{5}/', 'length_like' );
