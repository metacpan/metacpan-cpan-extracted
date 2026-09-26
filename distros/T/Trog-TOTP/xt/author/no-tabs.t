use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Trog/TOTP.pm',
    't/00-compile.t',
    't/01-rfc-test-vectors.t',
    't/02-base32.t',
    't/03-constructor-secret.t'
);

notabs_ok($_) foreach @files;
done_testing;
