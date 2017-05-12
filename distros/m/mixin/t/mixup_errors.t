#!/usr/bin/perl -w

use Test::More 'no_plan';
use Test::NoWarnings;

{
    package Not::A::Mixin;
    
    sub foo { 42 }
}

eval q{
    package Bar;
    use mixin 'Not::A::Mixin';
};
like $@, qr/\bis not a mixin\b/;
ok !Bar->can("foo");


{
    package Parent;
    sub wibble { "whomp" }
    
    package Foo;
    use mixin::with "Parent";
    sub yarrow { "hock" }
}

eval q{
    package Bar;
    use mixin 'Foo';
};
like $@, qr/\bBar must be a subclass of Parent to mixin Foo\b/;
ok !Bar->can("yarrow");