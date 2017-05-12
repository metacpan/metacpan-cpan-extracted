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
    is ($foo->name, 'One::foo', "name() does the right thing");
}
{
    my $pre_ret1 = foo();
    my $pre_ret2 = main::foo();

    is ($pre_ret1, 'mainfoo', 'calling a main:: sub without main:: works');
    is ($pre_ret2, 'mainfoo', 'calling a main:: sub with main:: works');

    my $wrap = Wrap::Sub->new;
    my $foo = $wrap->wrap('foo');

    is ($foo->name, 'main::foo', "name() adds main:: properly");
    is ($foo->is_wrapped, 1, "sub is confirmed wrapped");

    my $ret1 = foo();
    my $ret2 = main::foo();

    is ($ret1, 'mainfoo', 'calling a main:: wrap without main:: works');
    is ($ret2, 'mainfoo', 'calling a main:: wrap with main:: works');

    sub foo {
        return "mainfoo";
    }
}

done_testing();
