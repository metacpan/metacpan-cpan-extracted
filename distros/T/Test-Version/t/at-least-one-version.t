#!/usr/bin/perl
use 5.006;
use strict;
use warnings;
use Test::Tester;
use Test::More;
use Test::Version version_all_ok => {
	has_version        => 0,
	ignore_unindexable => 0,
};

my ( $premature, @results ) = run_tests(
	sub {
		version_all_ok('corpus/noversion');
	}
);

is( scalar(@results), 2, 'correct number of results' );

my @oks;

foreach my $result ( @results ) {
	push @oks, $result->{ok};
}

my $sorted = [ sort @oks ];

my $expected = [ ( 0, 1 ) ];

note( 'unsorted oks: ', @oks );

is_deeply( $sorted, $expected, 'oks are ok' );
done_testing;
