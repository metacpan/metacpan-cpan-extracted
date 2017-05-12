use strict;

package Foo;

sub bar {}
sub foo {}
sub qux {}

use namespace::clean::xs -except => 'qux';

package main;
use Test::More;

BEGIN {
    my $store = namespace::clean::xs->get_class_store('main');
    is scalar keys %{ $store->{exclude} }, 0;
    is scalar keys %{ $store->{remove} }, 0;
}

BEGIN {
    my $store = namespace::clean::xs->get_class_store('Foo');
    is scalar keys %{ $store->{exclude} }, 1;
    is scalar keys %{ $store->{remove} }, 2;

    is exists $store->{exclude}{qux}, 1;
    is exists $store->{remove}{bar}, 1;
    is exists $store->{remove}{foo}, 1;
}

done_testing;
