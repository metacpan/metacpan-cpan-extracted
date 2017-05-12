#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Wrap::Sub');
};

{
    my $wrap = Wrap::Sub->new;
    my $foo = $wrap->wrap('One::foo');

    eval { $foo->rewrap; };
    like ($@, qr/can't call rewrap/, "can't call rewrap on a wrapped sub");
}
{
    my $wrap = Wrap::Sub->new;
    my $foo = $wrap->wrap('One::foo');

    is ($foo->is_wrapped, 1, "sub is wrapped");

    $foo->unwrap;

    is ($foo->is_wrapped, 0, "sub is unwrapped");

    $foo->rewrap;

    is ($foo->is_wrapped, 1, "sub is re-wrapped with rewrap()");
}

done_testing();

