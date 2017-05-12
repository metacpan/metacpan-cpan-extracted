#!perl -w
use strict;
use lib qw(lib ../lib);
use Test::More tests => 1;

use URI::Title qw(title);

# it's much easier to test for failure
is(title('nonsense'), undef, "Title of nonsense is blank");
