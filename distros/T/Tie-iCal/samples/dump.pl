use Tie::iCal;
use Data::Dumper;

my $tievar = tie my %events, 'Tie::iCal', $ARGV[0], 'debug' => 0 or die "Failed to tie file!\n";

while (($uid, $event) = each %events) { 

	print "\nUID:$uid\n";
	print Dumper($event)."\n";

}
