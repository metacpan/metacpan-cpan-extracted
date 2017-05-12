#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 2;

use YAML::Syck;

my $some_hashref = { a => 1, b => 2 };
my $expected_iterations = scalar keys %$some_hashref;

is(
    count_each_iterations($some_hashref),
    $expected_iterations,
    "each() iterates properly before YAML::Syck::Dump",
);

# Perform the Dump.
my $some_yaml_dump = YAML::Syck::Dump($some_hashref);

is(
    count_each_iterations($some_hashref),
    $expected_iterations,
    "each() iterates properly after YAML::Syck::Dump",
);

exit;

sub count_each_iterations {
    my $hashref = shift;

    my $iterations = 0;
    while ( my ( $k, $v ) = each %$hashref ) {
        $iterations++;
    }

    return $iterations;
}
