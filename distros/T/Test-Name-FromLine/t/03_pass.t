use strict;
use warnings;
use lib 'lib';
use Test::More;
use Test::Name::FromLine;
use Test::Fatal;

is exception {
	pass "foo";
}, undef;

done_testing;

