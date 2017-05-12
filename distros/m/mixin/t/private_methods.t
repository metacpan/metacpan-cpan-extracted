#!/usr/bin/perl -w

use Test::More 'no_plan';
use Test::NoWarnings;

{
    package Foo;
    use mixin::with 'UNIVERSAL';
    
    sub public   { 42 }
    sub _private { 23 }
}

{
    package Bar;
    use mixin 'Foo';
}
can_ok "Bar", "public";
ok !Bar->can("_private"), "private methods not mixed in";
