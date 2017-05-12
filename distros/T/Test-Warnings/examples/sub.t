use strict;
use warnings;

use Test::More tests => 4;
use Test::Warnings ':all';

sub foo
{
    is(1, 1, 'passing test');

    had_no_warnings;

    warn 'this warning will cause a failure';

    had_no_warnings;    # failing test
}

foo;

# END will generate a failing test too
