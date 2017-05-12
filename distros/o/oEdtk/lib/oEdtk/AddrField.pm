package oEdtk::AddrField;

use strict;
use warnings;

use oEdtk::Main qw(oe_uc_sans_accents);
use base 'oEdtk::Field';
our $VERSION		= 0.01;

sub process {
	my ($self, $data) = @_;

	$data =~ s/^\s+//;
	$data =~ s/\s+$//;
	oe_uc_sans_accents($data);
	return uc($data);
}

1;
