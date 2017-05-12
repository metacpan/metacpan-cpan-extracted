use Test::More 0.95;

use Tie::Cycle;

my @array = qw( A );

tie my $cycle, 'Tie::Cycle', \@array;

is( $cycle, $array[0], "Cycle is first element, iteration 1" );
is( $cycle, $array[0], "Cycle is first element, iteration 2" );
is( $cycle, $array[0], "Cycle is first element, iteration 3" );

done_testing();
