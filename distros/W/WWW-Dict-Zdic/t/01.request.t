#!perl

use strict;
use warnings;
use utf8;
use encoding 'utf8';
use Test::More;
use WWW::Dict::Zdic;

if ($ENV{"ENABLE_ZDIC_TEST"}) {
    plan tests => 1;
} else {
    plan skip_all => 'Tests require to connect to zdic server';
}

my $dic = WWW::Dict::Zdic->new();

my $def = $dic->define("劉");

ok (exists $def->[0]{definition});
