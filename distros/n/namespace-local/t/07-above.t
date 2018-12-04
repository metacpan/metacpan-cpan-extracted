#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    package Foo;

    sub private {
        42;
    };

    use namespace::local -above;

    sub public {
        private();
    };
};

is( Foo->public, 42, "hidden function returns value" );
is( Foo->can("private"), undef, "hidden function is hidden" );

done_testing;


