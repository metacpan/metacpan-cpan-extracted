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

    my $foo = $wrap->wrap('One::foo', post => sub {return 'wrapped'; }, post_return => 1);
    my $ret = One::foo();
    is ($ret, 'wrapped', "One::foo is wrapped");

    $foo->unwrap;
    $ret = One::foo();
    is ($ret, 'foo', "One::foo is now unwrapped with unwrap()");

    $foo->rewrap;
    $ret = One::foo();

    is ($foo->called, 1, "call count is proper in obj void context");

    is ($ret, 'foo', "unwrap() calls reset()");

    $foo->post(sub {return 'rewrapped';}, post_return => 1);

    is (One::foo(), 'rewrapped', "rewrap() after unwrap() ok");

    $foo->unwrap;

    $ret = One::foo();
    is ($ret, 'foo', "One::foo is now unwrapped again");
}
{
    my $wrap = Wrap::Sub->new;

    my $pre_wrap_ret = One::foo();
    is ($pre_wrap_ret, 'foo', "pre_wrap value is $pre_wrap_ret");

    my $obj = $wrap->wrap('One::foo');
    $obj->post( sub {return 'wrapped'}, post_return => 1);

    my $post_wrap_ret = One::foo();
    is ($post_wrap_ret, 'wrapped', "post_wrap value is $post_wrap_ret");

    $obj->DESTROY;

    my $post_destroy_ret = One::foo();
    is ($post_destroy_ret, 'foo', "post_destroy value is $post_destroy_ret");

}
{
    # test DESTROY()

    my $wrap = Wrap::Sub->new;

    my $ret = One::foo();
    is ($ret, 'foo', "pre_wrap value is $ret");

    {
        my $foo = $wrap->wrap('One::foo', post => sub {return 'wrapped'}, post_return => 1);
        my $in_ret = One::foo();
        is ($in_ret, 'wrapped', "wrap value is $in_ret");
    }

    my $post_ret = One::foo();
    is ($post_ret, 'foo', "auto destroy/unwrap works properly")
}
{
    # test DESTROY() no calls

    my $wrap = Wrap::Sub->new;

    my $ret = One::foo();
    is ($ret, 'foo', "pre_wrap value is $ret");

    {
        my $foo = $wrap->wrap(
            'One::foo',
            return_value => 'wrapped',
            );
    }

    my $post_ret = One::foo();
    is ($post_ret, 'foo', "DESTROY() is called if the wrapped sub isn't called")
}

done_testing();
