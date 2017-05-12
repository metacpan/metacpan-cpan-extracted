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
    eval { Wrap::Sub->wrap('One::foo', side_effect => sub { die "died"; }); };
    like ($@, qr/\Qcan't call wrap() directly\E/, "class calling wrap() dies");
}
{
    my $wrap = Wrap::Sub->new;
    eval { $wrap->wrap('One::foo', side_effect => sub { die "died"; }); };
    like ($@, qr/in void context/, "obj calling wrap() in void context dies");
}
{
    my $child = Wrap::Sub::Child->new;
    eval { $child->wrap };
    like (
        $@, qr/Can't locate object method "wrap"/,
        "Wrap::Sub::Child no longer has a wrap() method"
    );
}
{
    my $wrap = Wrap::Sub->new;
    my $foo = $wrap->wrap('One::foo');

    $foo->post( sub { return 'wrapped'; }, post_return => 1);
    my $ret = One::foo();

    is ($ret, 'wrapped', "configured for the void test");

    $foo->unwrap;
    $ret = One::foo();

    is ($ret, 'foo', "child object is unwrapped");
    is ($foo->is_wrapped, 0, "confirm child obj is unwrapped");

    $foo->rewrap;
    $ret = One::foo();

    is ($foo->is_wrapped, 1, "rewrap() rewraps");
    is ($ret, 'foo', "child obj calling rewrap in void w/ params is wrapped");
}

done_testing();
