#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Test::More;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Wrap::Sub');
};
{
    my $wrap = Wrap::Sub->new;
    my $w = $wrap->wrap('One::foo');

    One::foo();

    is ($w->is_wrapped, 1, "sub is wrapped");

    $w->unwrap;

    is ($w->is_wrapped, 0, "sub is unwrapped");
}
{
    my $wrap = Wrap::Sub->new;

    my $foo = $wrap->wrap('One::foo');
    is ($foo->is_wrapped, 1, "obj 1 has proper wrap state");

    is ($wrap->is_wrapped('One::foo'), 1, "wrap has proper wrap state on obj 1");

    my $bar = $wrap->wrap('One::bar');
    is ($bar->is_wrapped, 1, "obj 2 has proper wrap state");
    is ($bar->is_wrapped, 1, "wrap has proper wrap state on obj 2");

    $foo->unwrap;
    is ($foo->is_wrapped, 0, "obj 1 has proper unwrap state");
    is ($wrap->is_wrapped('One::foo'), 0, "wrap has proper umwrap state on obj 1");

    my $wrap2 = Wrap::Sub->new;

    eval { $wrap2->is_wrapped('One::foo'); };
    like (
        $@,
        qr/can't call is_wrapped()/,
        "can't call is_wrapped() on parent if a child hasn't been initialized and wrapped"
    );

    $foo->rewrap;
    is ($foo->is_wrapped, 1, "obj has proper wrap state with 2 wraps");
    is ($foo->is_wrapped, 1, "...and original wrap obj still has state");

    eval { $wrap->is_wrapped; };
    like ($@, qr/calling is_wrapped()/, "can't call is_wrapped on a top-level obj");
}

done_testing();
