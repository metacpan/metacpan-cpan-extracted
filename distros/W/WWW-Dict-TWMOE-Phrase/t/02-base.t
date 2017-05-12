#!perl
use strict;
use warnings;
use WWW::Dict::TWMOE::Phrase;
use Test::More tests => 1;
my $dict = WWW::Dict::TWMOE::Phrase->new;
ok( $dict->isa("WWW::Dict") );
