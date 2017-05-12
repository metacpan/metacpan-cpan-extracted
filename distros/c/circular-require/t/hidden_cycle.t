#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/hidden_cycle';
use Test::More;

no circular::require -hide => [qw(Bar Baz)];

my @warnings;

{
    $SIG{__WARN__} = sub { push @warnings => @_ };

    use_ok( 'Foo' );
}

is_deeply(
    \@warnings,
    ["Circular require detected in Bar.pm (from unknown file)\n"],
    "hiding all packages in the cycle shouldn't report a package outside of the cycle as being the source"
);

done_testing;
