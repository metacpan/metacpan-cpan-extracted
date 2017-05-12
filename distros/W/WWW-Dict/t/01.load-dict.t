#!perl

use warnings;
use strict;
use WWW::Dict;

use Test::More tests => 1;

my $dict = WWW::Dict->new('Zdic');

is ( ref($dict), 'WWW::Dict::Zdic');
