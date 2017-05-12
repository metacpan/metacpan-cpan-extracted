
package StaticCB;

use Data::Dumper;
use Time::HiRes qw(sleep);

sub myhandler {
	my $range = shift;
	my $array = shift;

	for ( my $i = $range->begin; $i < $range->end; $i++ ) {
		my $item = $array->FETCH($i);
		sleep 0.1;
	}
}

sub map_func {
	my $item = shift;
	return( ($item % 7) x (int( ($item+6) / 7)) );
}
$map_func = 2;

1;
