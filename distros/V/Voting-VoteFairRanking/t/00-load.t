#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Voting::VoteFairRanking' );
}

diag( "Testing Voting::VoteFairRanking $Voting::VoteFairRanking::VERSION, Perl $], $^X" );
