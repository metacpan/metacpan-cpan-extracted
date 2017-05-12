#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Test::More;

BEGIN {
    use_ok('Wrap::Sub');
};

{
    my $wrap = Wrap::Sub->new;

    my $foo = $wrap->wrap('wrap');
    my $ret1 = wrap();

    is ($foo->is_wrapped, 1, "sub is wrapped");
    is ($ret1, 5, "before reset and no params, return is ok");

    $foo->post(post_return => 1, sub { return $_[1]->[0] + 5; });

    is (wrap(), 10, "post_return set and working");

    $foo->reset;

    for (qw (called_with pre post post_return)){
        is ($foo->{$_}, undef, "$_ is undef after reset");
    }

    my $ret2 = wrap(qw(1 2 3));
    is ($ret2, 5, "after reset, return is correct");



    is ($foo->is_wrapped, 1, "after reset, sub is still wrapped");
}

done_testing();

sub wrap {
    return 5;
}
