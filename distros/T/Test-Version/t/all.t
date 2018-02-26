#!/usr/bin/perl -T
use 5.006;
use strict;
use warnings;
use Test::Tester;
use Test::Version version_all_ok => { ignore_unindexable => 0 };
use Test::More;

my ( $premature, @results ) = run_tests(
	sub {
		version_all_ok('corpus');
	}
);

is( scalar(@results), 18, 'correct number of results' );

my @oks;

foreach my $result ( @results ) {
	push @oks, $result->{ok};
}

my $sorted = [ sort @oks ];

my $expected = [ ( 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 ) ];

note( 'unsorted oks: ', @oks );

is_deeply( $sorted, $expected, 'oks are ok' );
done_testing;
