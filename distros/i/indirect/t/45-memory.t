#!perl -T

use lib 't/lib';

use Test::More tests => 1;

BEGIN { delete $ENV{PERL_INDIRECT_PM_DISABLE} }

eval "require indirect::Test0::Oooooo::Pppppppp";
is($@, '', 'memory reallocation to an uncatched optype');
