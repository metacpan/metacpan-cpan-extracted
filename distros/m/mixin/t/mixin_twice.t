#!/usr/bin/perl -w

use Test::More 'no_plan';
use Test::NoWarnings;

{
    package Foo;
    use mixin::with 'UNIVERSAL';
    
    sub foo { 42 }
}

{
    package Bar;
    
    # Using a mixin twice should work.  It might warn in the future, dunno.
    use mixin 'Foo';
    use mixin 'Foo';
}
is( Bar->foo, 42 );