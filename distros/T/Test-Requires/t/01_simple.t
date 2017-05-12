BEGIN { $ENV{RELEASE_TESTING} = 0 };
use strict;
use warnings;
use Test::More tests => 10;
use Test::Requires;

test_requires 'Acme::Unknown::Missing::Module::Name';

fail 'do not reach here';

