#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::Exception tests => 3;

use WWW::Sixpack;
my $sp = WWW::Sixpack->new();
throws_ok { $sp->participate('-bad-name', []); } qr/Bad experiment name/, 'Bad experiment name';
throws_ok { $sp->participate('good-name', ['one']); } qr/Must specify at least 2 alternatives/, 'Not enough alternatives';
throws_ok { $sp->participate('good-name', ['one', '-bad-two']); } qr/Bad alternative name/, 'Bad alternative name';


