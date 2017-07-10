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
        isa    => Int(),
        result => 1,
    },
    {
        value  => [ 1, 2, 3 ],
        isa    => ArrayRef( Int() ),
        result => 1,
    },
    {
        value  => [ 'x', 'y', 'z' ],
        isa    => ArrayRef( Int() ),
        result => 0,
    },
    {
        value  => [ 'x', 'y', 'z' ],
        isa    => ArrayRef( Str() ),
        result => 1,
    },
    {
        value  => { foo => 1, bar => 2 },
        isa    => HashRef( Int() ),
        result => 1,
    },
    {
        value  => { foo => 'x', bar => 'y' },
        isa    => HashRef( Int() ),
        result => 0,
    },
    {
        value  => { foo => 'x', bar => 'y' },
        isa    => HashRef( Str() ),
        result => 1,
    },
    {
        value  => { foo => [ 1, 2, 3 ] },
        isa    => HashRef( ArrayRef( Int() ) ),
        result => 1,
    },
);

foreach my $test (@tests) {
    is( validate( $test->{isa}, $test->{value} ), $test->{result} );
}

# final test: test the @tests :-)

ok( validate( ArrayRef( HashRef( Any() ) ), \@tests ) );
