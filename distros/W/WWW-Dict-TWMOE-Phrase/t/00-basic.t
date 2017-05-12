#!/usr/bin/perl
use strict;
use warnings;
use encoding 'utf8';
use WWW::Dict::TWMOE::Phrase;
use Test::More tests => 2;

my $dict = WWW::Dict::TWMOE::Phrase->new();
my $def = $dict->define("風");

ok(ref $def eq 'ARRAY');
ok(ref $def->[0] eq 'HASH');

