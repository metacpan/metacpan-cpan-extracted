#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 2;
use WWW::Dict::Zdic;
use YAML;

my $yaml = YAML::LoadFile("t/content");
my $content = $yaml->[0];
my $dic = WWW::Dict::Zdic->new();
my $def = $dic->parse_content($content);

ok( exists $def->[0]{definition} );
ok( exists $def->[1]{definition} );

