package Test::UniqueTestNames::Tracker;

use strict;
use warnings;

use Test::UniqueTestNames::Test;

my %tests;

sub add_test {
    my ( $class, $name, $line_number ) = @_;

    die "add_test must have a line number" unless defined $line_number;
    $name ||= '<no test name>';

    unless ( exists $tests{ $name } ) {
        $tests{ $name } = Test::UniqueTestNames::Test->new( $name, $line_number );
    }
    else {
        $tests{ $name }->add_line_number( $line_number );
    }
}

sub all_tests {
    return [ values %tests ];
}

sub failing_tests {
    my ( $class ) = @_;

    my @failing_tests;

    for( sort { $a->lowest_line_number <=> $b->lowest_line_number } values %tests ) {
        push @failing_tests, $_ if $_->fails;
    }

    return \@failing_tests;
}

sub unnamed_ok {
    my ( $class, $value ) = @_;
    Test::UniqueTestNames::Test->unnamed_ok( $value );
}

1;
