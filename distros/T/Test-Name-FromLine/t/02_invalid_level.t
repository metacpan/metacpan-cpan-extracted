use strict;
use warnings;
use lib 'lib';
use Test::More;
use Test::Name::FromLine;
use Test::Fatal;


is exception {
	local $Test::Builder::Level = 9999;
	ok 1;
}, undef;

done_testing;
