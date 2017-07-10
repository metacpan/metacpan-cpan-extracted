#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use Type::Simple qw(
    validate
    Maybe
    Bool
    Int
    HashRef
    HashRefWith
);

my @tests = (
    {
        value  => { foo => 1, bar => 2 },
        type   => HashRef(),
        result => 1,
    },
    {
        value  => { foo => 1, bar => 2 },
        type   => HashRef( Int() ),
        result => 1,
    },
    {
        value  => { foo => 1, bar => 2 },
        type   => HashRefWith( foo => Int(), bar => Int() ),
        result => 1,
    },
    {
        value  => { foo => 1, bar => 2 },
        type   => HashRefWith( foo => Int(), bar => Int(), baz => Int() ),
        result => 0,
    },
    {
        value  => { foo => 1, bar => 2 },
        type   => HashRefWith( foo => Int(), bar => Int(), baz => Maybe(Int()) ),
        result => 1,
    },
);

foreach my $test (@tests) {
    is( validate( $test->{type}, $test->{value} ), $test->{result} );
}

# Exception case:
eval {
    is( validate( HashRefWith( Int() => Int() ), { 1 => 2, 3 => 4 } ), 1 );
    fail('Test should raise exception!');
    1;
} or do {
    my ($error) = $@;
    if ($error =~ /^Key "[^"]+" should be a string/) {
        pass("Raised correct exception - $error");
    } else {
        fail("Raised wrong exception ($error)");
    }
};
