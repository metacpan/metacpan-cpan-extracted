use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

{
    package Foo;
    use me::inlined;
    sub foo { return 3 * shift }

    package Bar;
    use Foo;
    sub bar { return 2 * Foo::foo(shift) }
}

is($INC{'Foo.pm',}, __FILE__, '%INC is updated');

is(Bar::bar(5), 30, 'Foo can find the Bar package later in its own file');

done_testing;
