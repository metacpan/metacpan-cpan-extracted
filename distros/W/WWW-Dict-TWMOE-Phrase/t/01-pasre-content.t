#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use WWW::Dict::TWMOE::Phrase;

my $dict = WWW::Dict::TWMOE::Phrase->new();

$/ = undef;
open F, "<:encoding(big5)", "t/content.html";
my $content = <F>;

my $def = $dict->parse_content($content);

ok(ref $def eq 'HASH');
ok(exists $def->{zuin_form_1});
ok(exists $def->{zuin_form_2});
ok(exists $def->{synonym});
ok(exists $def->{antonym});
ok(exists $def->{definition});


