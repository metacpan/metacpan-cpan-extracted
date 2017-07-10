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
                    Alpha
                    Alnum
                    Ascii
                    Num
                        Int
                    Print
                    Punct
                    Space
                    Word
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
        value  => [ 'foo', 123 ],
        isa    => ArrayRef( Type::Simple::OR( Alpha(), Num() ) ),
        result => 1,
    },
    {
        value  => { foo => 1, bar => 'xyz' },
        isa    => HashRef( Type::Simple::OR( Alpha(), Num() ) ),
        result => 1,
    },
    {
        value  => { foo => 'xyz', bar => [], baz => undef },
        isa    => HashRef( Type::Simple::NOT( Num() ) ),
        result => 1,
    },
    {
        value  => 1.23,
        isa    => Type::Simple::AND( Num(), Type::Simple::NOT( Int() ) ), # non-integer number
        result => 1,
    },
    {
        value  => 123,
        isa    => Type::Simple::AND( Num(), Type::Simple::NOT( Int() ) ), # non-integer number
        result => 0,
    },
    {
        value  => 'abc',
        isa    => Type::Simple::AND( Str(), Type::Simple::NOT( Num() ) ), # non-numeric string
        result => 1,
    },
    {
        value  => 'abc123',
        isa    => Type::Simple::AND( Str(), Type::Simple::NOT( Num() ) ), # non-numeric string
        result => 1,
    },
    {
        value  => '123',
        isa    => Type::Simple::AND( Str(), Type::Simple::NOT( Num() ) ), # non-numeric string
        result => 0,
    },
);

foreach my $test (@tests) {
    is( validate( $test->{isa}, $test->{value} ), $test->{result} );
}
