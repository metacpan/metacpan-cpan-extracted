package FirstBase;

use strict;
use warnings;

sub new { return bless {}, shift; }

sub firstBase {
	my $obj = shift;
	return ($obj->{_case} eq 'uc') ? 'FIRSTBASE' : 'firstbase';
}
#
#	implement, but don't inherit
#
sub get_simplex_methods {
	return {};
}

sub get_urgent_methods {
	return {};
}

1;

