#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use Type::Simple qw(
    validate
    Any
        Bool
        Maybe
        Undef
        Defined
            Value
                Str
                    Num
                        Int
            Ref
                ScalarRef
                ArrayRef
                HashRef
                CodeRef
                RegexpRef
                Object
);

my @tests = (
    {
        value  => 123,
        type   => Ref(),
        result => 0,
    },
    {
        value  => \123,
        type   => Ref(),
        result => 1,
    },
    {
        value  => \123,
        type   => ScalarRef(),
        result => 1,
    },
    {
        value  => [ 1, 2, 3 ],
        type   => ArrayRef(),
        result => 1,
    },
    {
        value  => { foo => 1, bar => 2 },
        type   => HashRef(),
        result => 1,
    },
    {
        value  => sub {123},
        type   => CodeRef(),
        result => 1,
    },
    {
        value  => qr/.+/,
        type   => RegexpRef(),
        result => 1,
    },
    {
        value  => {},
        type   => Object(),
        result => 0,
    },
    {
        value  => bless( {}, 'FOO' ),
        type   => Object(),
        result => 1,
    },
);

foreach my $test (@tests) {
    is( validate( $test->{type}, $test->{value} ), $test->{result} );
}

# final test: test the @tests :-)

ok( validate( ArrayRef( HashRef( Any() ) ), \@tests ) );
