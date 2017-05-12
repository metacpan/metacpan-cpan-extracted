use strict;
use warnings;

use Test::Strict;
use Test::More;

unless($ENV{RELEASE_TESTING}) {
    plan skip_all => 'Author test not required for installation';
}

all_cover_ok(80, 't/');
