#!perl
# checking 'language' attribute

use strict;
use warnings;
use WWW::FMyLife;

use Test::More tests => 4;

my $fml = WWW::FMyLife->new();
is( $fml->language, 'en', 'default language is English' );

$fml->language('fr');
is( $fml->language, 'fr', 'can change language to French' );

$fml = WWW::FMyLife->new( { language => 'en' } );
is( $fml->language, 'en', 'Can set language on initialize to English' );

$fml = WWW::FMyLife->new( { language => 'fr' } );
is( $fml->language, 'fr', 'Can set language on initialize to French' );

