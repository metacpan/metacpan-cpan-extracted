#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Wrap::Sub');
};

{# wrap() instantiate

    my $wrap = Wrap::Sub->new;
    my $test = $wrap->wrap('One::foo');
    is (ref $test, 'Wrap::Sub::Child', '$wrap->wrap() returns a child object');

    Two::test;
    is ($test->is_wrapped, 1, "wrap() wraps");
}
{
    my $wrap = Wrap::Sub->new;
    my $test5;
    eval { $test5 = $wrap->wrap('testing'); };
    is ($test5->{name}, 'main::testing', "main:: gets prepended properly");
    is ($@, '', "sub param automatically gets main:: if necessary");
    is (testing(), 'testing', "sub in main:: is called properly")
}
{
    my $wrap = Wrap::Sub->new;
    eval { my $fake = $wrap->wrap('X::y'); };
    like ($@, qr/\Qcan't wrap() a non-existent sub\E/, "can't wrap a non-sub");
}
{
    eval { my $foo = Wrap::Sub->wrap('One::foo'); };
    like ($@, qr/\Qcan't call wrap() \E/, "can't call wrap() from the Wrap::Sub class");
}
{
    my $wrap = Wrap::Sub->new;
    my $foo = $wrap->wrap('One::foo');

    eval { "Wrap::Sub::Child"->_wrap('One::foo'); };

    like ($@, qr/\Qwrap() is not a public method\E/, "can't call wrap() from the Wrap::Sub class");
}

done_testing();

sub testing {
    return 'testing';
}
