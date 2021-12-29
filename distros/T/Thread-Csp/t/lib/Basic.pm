package Basic;

use strict;
use warnings;

sub basic {
	my ($q, $second) = @_;
	my $first = $q->receive;
	$q->send($first * $second);
	13;
}

sub closed {
	my $q = shift;
	my $result = 0;
	while (my $next = $q->receive) {
		$result += $next;
	}
	return $result;
}

1;
