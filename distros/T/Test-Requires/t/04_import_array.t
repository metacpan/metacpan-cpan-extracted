BEGIN { $ENV{RELEASE_TESTING} = 0 };
use strict;
use warnings;
use Test::More;
use Test::Requires qw(
    Acme::Unknown::Missing::Module::Name
);
plan tests => 3;

fail 'do not reach here';

