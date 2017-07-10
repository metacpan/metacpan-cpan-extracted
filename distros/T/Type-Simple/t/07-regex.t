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
        isa    => ArrayRef( qr{^[\w\d]+$} ),
        result => 1,
    },
    {
        value  => { foo => 1, bar => 'xyz' },
        isa    => HashRef( Type::Simple::OR( qr{^\w+$}, qr{^\d+$} ) ),
        result => 1,
    },
    {
        value  => { foo => 1, bar => 'xyz' },
        isa    => HashRef( Type::Simple::NOT( qr{\s} ) ),
        result => 1,
    },
);

foreach my $test (@tests) {
    is( validate( $test->{isa}, $test->{value} ), $test->{result} );
}
