#!perl
use strict;
use warnings;
use WWW::Dict::Zdic;
use Test::More tests => 1;
my $dict = WWW::Dict::Zdic->new;
ok( $dict->isa("WWW::Dict") );
