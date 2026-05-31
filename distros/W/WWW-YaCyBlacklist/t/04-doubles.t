#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 2;

require_ok( 'WWW::YaCyBlacklist' );

my $ycb = WWW::YaCyBlacklist->new( { 'use_regex' => 1 } );
$ycb->read_from_array(
    'test1.co/fullpath',
    'test2.co/fullpath',
    'test2.co/fullpath',
    'test2.co/.*',
    'test1.co/.*',
    'test2.co/fullpath',
);
cmp_ok( $ycb->length, '==', 4, 'numerical' );