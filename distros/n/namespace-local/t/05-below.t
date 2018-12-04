#!perl

use strict;
use warnings;
use Test::More;

{
    package Foo;
    sub public {
        private();
    };

    use namespace::local -below;

    sub private {
        return 42;
    };
};

is( Foo->public, 42, "code works after all" );

is( Foo->can("private"), undef, "private sub not resolved" );

done_testing;

