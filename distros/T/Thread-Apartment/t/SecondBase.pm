package SecondBase;

use FirstBase;
use base qw(FirstBase);

use strict;
use warnings;

sub new { return bless {}, shift; }

sub secondBase {
	my $obj = shift;
	return ($obj->{_case} eq 'uc') ? 'SECONDBASE' : 'secondbase';
}
#
#	get base class's methods as well as our own
#
sub get_simplex_methods {
	my $obj = shift;

	my $simplex = $obj->FirstBase::get_simplex_methods();
	$simplex->{"FirstBase::$_"} = 1
		foreach (keys %$simplex);
	return $simplex;
}

sub get_urgent_methods {
	my $obj = shift;

	my $urgent = $obj->FirstBase::get_urgent_methods();
	$urgent->{"FirstBase::$_"} = 1
		foreach (keys %$urgent);
	return $urgent;
}

1;

