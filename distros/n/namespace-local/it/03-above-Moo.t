#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    if (!eval { require Moo; 1 }) {
        warn "WARNING: $@" unless $@ =~ /Can't locate Moo.pm/;
        plan skip_all => "No Moo found";
        exit 0;
    };
};

lives_ok {
    package Foo;
    use Moo;

    use namespace::local -above;

    has boo => is => "rw";
} "moo works correctly";

my $foo = Foo->new( boo => 42 );

is( $foo->boo, 42, "Moo works unchallenged" );
is( Foo->can("has"), undef, "hidden function (has) is hidden" );

done_testing;


