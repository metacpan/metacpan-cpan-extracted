use strict;
use warnings;
use Test::More 0.88;

{
    package Foo;
    use Test::Requires 'Sub::Install';
    sub bar { }

    Sub::Install::install_sub({
        code => sub { 'moo!' },
        into => __PACKAGE__,
        as   => 'moo',
    });

    use namespace::autoclean;
}

ok( Foo->can('bar'), 'Foo can bar - standard method');
ok( Foo->can('moo'), 'Foo can moo - installed sub');

done_testing;
