use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

{
    package Foo;
    use me::inlined;
    my $multiplicand;
    sub import
    {
        my ($self, $m) = @_;
        $multiplicand = $m;
    }
    sub foo { return ($multiplicand || 3) * shift }

    package Bar;
    use Foo '7';
    sub bar { return 2 * Foo::foo(shift) }
}

is(Bar::bar(5), 70, 'Foo can find the Bar package later in its own file, and pass an import arg');

done_testing;
