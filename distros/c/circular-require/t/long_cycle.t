#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/long_cycle';

no circular::require;

my @warnings;

{
    $SIG{__WARN__} = sub { push @warnings => @_ };

    use_ok( 'Foo' );
}

is_deeply(
    \@warnings,
    ["Circular require detected:\n  Bar.pm\n  Baz.pm\n  Quux.pm\n  Blorg.pm\n  Bar.pm\n"],
    "detection of longer cycles"
);

done_testing;
