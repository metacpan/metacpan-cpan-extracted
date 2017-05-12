use Test::More;

use Tie::Cycle;

my @array = qw( A B C );

tie my $cycle, 'Tie::Cycle', \@array;

foreach( 0 .. 2 ) {
	is( $cycle, $array[0], "Cycle is first element, iteration $_" );
	is( $cycle, $array[1], "Cycle is second element, iteration $_" );
	is( $cycle, $array[2], "Cycle is third element, iteration $_" );
	}

done_testing();
