#!/usr/bin/perl

use strict;
use warnings;

use Scalar::Util qw(looks_like_number);

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
        value => undef,
        isa   => {
            Any      => 1,
            Bool     => 1,
            Value    => 0,
            Str      => 0,
        },
    },
    {
        value => '',
        isa   => {
            Any      => 1,
            Bool     => 1,
            Value    => 1,
            Str      => 1,
        },
    },
    {
        value => 0,
        isa   => {
            Any      => 1,
            Bool     => 1,
            Value    => 1,
            Str      => 1,
        },
    },
    {
        value => 1,
        isa   => {
            Any      => 1,
            Bool     => 1,
            Value    => 1,
            Str      => 1,
        },
    },
    {
        value => 1000,
        isa   => {
            Any      => 1,
            Bool     => 0,
            Value    => 1,
            Str      => 1,
        },
    },
    {
        value => 3.14,
        isa   => {
            Any      => 1,
            Bool     => 0,
            Value    => 1,
            Str      => 1,
        },
    },
    {
        value => 'abc',
        isa   => {
            Any      => 1,
            Bool     => 0,
            Value    => 1,
            Str      => 1,
        },
    },
    {
        value => [],
        isa   => {
            Any      => 1,
            Bool     => 0,
            Value    => 0,
            Str      => 0,
        },
    },
    {
        value => {},
        isa   => {
            Any      => 1,
            Bool     => 0,
            Value    => 0,
            Str      => 0,
        },
    },
);

foreach my $test (@tests) {
    my $value = $test->{value};
    my $isa   = $test->{isa};

    note( sprintf '===== %s =====', $value // 'undef' );

    is( validate( Any(),   $value ), $isa->{Any},   'Any' );
    is( validate( Bool(),  $value ), $isa->{Bool},  'Bool' );
    is( validate( Value(), $value ), $isa->{Value}, 'Value' );
    is( validate( Str(),   $value ), $isa->{Str},   'Str' );

    is( !!validate( Defined(), $value ), !!( defined($value) ),     'Defined' );
    is( !!validate( Undef(),   $value ), !!( not defined($value) ), 'Defined' );

    is( !!validate( Num(), $value ), !!looks_like_number($value), 'Num' );
    is( !!validate( Int(), $value ), !!( looks_like_number($value) and int($value) == $value ), 'Int' );

    is( !!validate( Ref(),      $value ), !!( ref $value ),            'Ref' );
    is( !!validate( ArrayRef(), $value ), !!( ref $value eq 'ARRAY' ), 'ArrayRef' );
    is( !!validate( HashRef(),  $value ), !!( ref $value eq 'HASH' ),  'HashRef' );
}
