#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 4;

require_ok( 'WWW::YaCyBlacklist' );

my $ycb = WWW::YaCyBlacklist->new();
is( $ycb->use_regex, 1, 'empty' );

$ycb = WWW::YaCyBlacklist->new( { 'use_regex' => 1 } );
is( $ycb->use_regex, 1, 'regex' );

$ycb = WWW::YaCyBlacklist->new( { 'use_regex' => 0 } );
is( $ycb->use_regex, 0, 'noregex' );