#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 7;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Wrap::Sub');
};

{
    my $wrap = Wrap::Sub->new;

    my $foo = $wrap->wrap('One::foo');
    my $bar = $wrap->wrap('One::bar');
    my $baz = $wrap->wrap('One::baz');

    my @names;

    @names = $wrap->wrapped_subs;

    is (@names, 3, "return is correct");

    $foo->unwrap;

    @names = $wrap->wrapped_subs;
    is (@names, 2, "after unwrap, return is correct");
    my @ret1 =  grep /One::foo/, @names;
    is ($ret1[0], undef, "the unwrapped sub isn't in the list of names");

    $foo->rewrap('One::foo');

    @names = $wrap->wrapped_subs;

    my @ret2 =  grep /One::foo/, @names;
    is (@names, 3, "after re-wrap, return is correct");
    is ($ret2[0], 'One::foo', "the unwrapped sub isn't in the list of names");
}
