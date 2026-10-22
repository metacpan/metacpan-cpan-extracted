package oEdtk::SignedField;

# Decode a signed amount field encoded using Infinite conventions.

use strict;
use warnings;

use base 'oEdtk::Field';
our $VERSION = 2.1131;

sub new {
	my ( $class, $name, $ilen, $flen ) = @_;

	$flen = 0 unless defined($flen);
	my $self = $class->SUPER::new( $name, $ilen + $flen );
	$self->{'intlen'}  = $ilen;
	$self->{'fraclen'} = $flen;
	return $self;
}

sub process {
	my ( $self, $data ) = @_;

	$data =~ s/\s+//g;

	if ( $data !~ /^-?\d*[p-y]?$/ ) {
		warn "INFO: Unexpected numerical value: $data in " . $self->{'name'} . "\n";
	}

	if ( $data eq '' ) {
		$data = 0;
	}
	if ( $data =~ s/([p-y])$/ord($1) - ord('p')/e ) {
		$data *= -1;
	}

	my $flen = $self->{'fraclen'};
	if ( $data !~ /\./ && $flen > 0 ) {
		$data /= 10**$flen;
		return sprintf( "%.${flen}f", $data );
	}
	return $data;
}

1;

=head1 NAME

oEdtk::SignedField - signed amount field (Infinite encoding)

=head1 SYNOPSIS

    use oEdtk::SignedField;

    my $field = oEdtk::SignedField->new('MONTANT', 8, 2);
    print $field->process('00001234'), "\n";   # '12.34'

=head1 DESCRIPTION

An C<oEdtk::Field> subclass decoding a signed amount that follows the Infinite
convention: the trailing byte, when it is a letter in the range C<p>..C<y>,
both carries the last digit and marks the amount negative. A value whose shape
does not match the expected form raises a warning.

=head1 METHODS

=head2 new

    my $field = oEdtk::SignedField->new($name, $ilen, $flen);

Construct a field whose byte length is C<$ilen + $flen>. C<$flen> defaults to
C<0>.

=head2 process

    my $value = $field->process($data);

Strip the blanks from C<$data>; warn when it is not a plain (optionally signed)
number with an optional trailing C<p>..C<y> letter. An empty value becomes
C<0>; a trailing C<p>..C<y> letter replaces the last digit with its value and
negates the amount. When C<$flen> is set the value is scaled and formatted with
C<$flen> decimals.

=head1 AUTHOR

The oEdtk team.

=cut
