#!perl
use strict;
use warnings;
use WWW::Dict;
use Test::More tests => 2;
my $dict = WWW::Dict->new('TWMOE::Phrase');
ok ( $dict->isa( 'WWW::Dict' ) );
ok ( $dict->isa( 'WWW::Dict::TWMOE::Phrase' ) );
