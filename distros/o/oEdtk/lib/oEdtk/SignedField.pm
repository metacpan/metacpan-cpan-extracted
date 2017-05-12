package oEdtk::SignedField;

# Decode a signed amount field encoded using Infinite conventions.

use strict;
use warnings;

use base 'oEdtk::Field';
our $VERSION		= 0.01;

sub new {
	my ($class, $name, $ilen, $flen) = @_;

	$flen = 0 unless defined($flen);
	my $self = $class->SUPER::new($name, $ilen + $flen);
	$self->{'intlen'} = $ilen;
	$self->{'fraclen'} = $flen;
	return $self;
}

sub process {
	my ($self, $data) = @_;

	$data =~ s/\s+//g;

	if ($data !~ /^-?\d*[p-y]?$/) {
		warn "INFO : Unexpected numerical value: $data in ".$self->{'name'}."\n";
	}

	if ($data eq '') {
		$data = 0;
	}
	if ($data =~ s/([p-y])$/ord($1) - ord('p')/e) {
		$data *= -1;
	}

	my $flen = $self->{'fraclen'};
	if ($data !~ /\./ && $flen > 0) {
		$data /= 10 ** $flen;
		return sprintf("%.${flen}f", $data);
	}
	return $data;
}

1;
