package oEdtk::FPField;

use strict;
use warnings;

use base 'oEdtk::Field';
our $VERSION		= 0.01;

sub new {
	my ($class, $name, $ilen, $flen) = @_;

	$flen = 0 if (!(defined $flen));
	my $self = $class->SUPER::new($name, $ilen + $flen);
	$self->{'intlen'} = $ilen;
	$self->{'fraclen'} = $flen;
	return $self;
}

sub process {
	my ($self, $data) = @_;

	$data =~ s/\s+//g;
	my $flen = $self->{'fraclen'};
	return $data if $data eq '';

	if ($data !~ /\./) {
		$data /= 10 ** $flen;
	}
	return sprintf("%.${flen}f", $data);
}

1;
