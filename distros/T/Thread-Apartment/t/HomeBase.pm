package HomeBase;

use strict;
use warnings;

sub new { 
	my ($class, $case) = @_;
	return bless { _case => $case }, $class; 
}

sub homeBase {
	my $obj = shift;
	return ($obj->{_case} eq 'uc') ? 'HOMEBASE' : 'homebase';
}

sub error {
	$@ = 'booted ball!';
	return undef;
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

