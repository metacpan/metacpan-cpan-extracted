#!perl

use strict;
use warnings;
use Test::More;
use Test::Differences;

my %cases = (
    'AoH with non-scalar values' => {
        got      => [ { a => 1 }, { b => 1, c => [] } ],
        expected => [ { a => 1 }, { b => 1, c => [] } ]
    },
    'Numbers and strings' => {
        got      => { order_id => 127   },
        expected => { order_id => '127' },
    },
);

my @tests;
while ( my ( $name, $test ) = each %cases ) {
    push @tests => sub { eq_or_diff $test->{got}, $test->{expected}, $name };
}

plan tests => scalar @tests;

$_->() for @tests;
