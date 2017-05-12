#!perl -w

use strict;
use Test::More tests => 2;

use WeakRef::Auto;

my $var = [42];

Internals::SvREADONLY($var, 1);

eval{
	autoweaken $var;
};
like $@, qr/read-only/;

is_deeply $var, [42];
