#!/usr/bin/perl

use utf8;
use strict;
use warnings;
use IO::All;
use WWW::Lipsum::Chinese;
use Test::More tests => 1;

my $lipsum = WWW::Lipsum::Chinese->new;

my $text = $lipsum->generate;

ok($text);

