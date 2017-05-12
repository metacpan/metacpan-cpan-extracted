#!perl
# checking 'key' attribute

use strict;
use warnings;
use WWW::FMyLife;

use Test::More tests => 5;

my $fml = WWW::FMyLife->new();
is( $fml->key, 'readonly', 'Default key is readonly' );

$fml->key('myveryownkey');
is( $fml->key, 'myveryownkey', 'Can change key' );

$fml = WWW::FMyLife->new( { key => 'myveryownkey' } );
is( $fml->key, 'myveryownkey', 'Can set key on initialize' );

$fml = WWW::FMyLife->new( { key => 'ack', language => 'fr' } );
is( $fml->key,      'ack', 'Can set key on init while setting language' );
is( $fml->language, 'fr',  'Can set language on init while setting key' );
