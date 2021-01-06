use warnings;
use strict;

use Test::More;
use ExtUtils::Manifest;

if (! $ENV{RELEASE_TESTING}) {
    plan skip_all => "Author tests not required for installation";
}

is_deeply [ ExtUtils::Manifest::manicheck() ], [], 'missing';
is_deeply [ ExtUtils::Manifest::filecheck() ], [], 'extra';

done_testing;
