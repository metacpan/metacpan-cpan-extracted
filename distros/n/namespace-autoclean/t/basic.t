use strict;
use warnings;
use Test::More 0.88;

{
    package Foo;
    sub bar { }
    use namespace::autoclean;
    sub moo { }
    BEGIN { *kooh = *kooh = do { package Moo; sub { }; }; }
    BEGIN { *affe = *affe = sub { }; }
}

ok( Foo->can('bar'), 'Foo can bar - standard method');
ok( Foo->can('moo'), 'Foo can moo - standard method');
ok(!Foo->can('kooh'), 'Foo cannot kooh - anon sub from another package assigned to glob');
ok( Foo->can('affe'), 'Foo can affe - anon sub assigned to glob in package');

done_testing();
