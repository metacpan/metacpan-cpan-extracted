package oEdtk::FPField;

use strict;
use warnings;

use base 'oEdtk::Field';
our $VERSION = 2.1126;

sub new {
	my ( $class, $name, $ilen, $flen ) = @_;

	$flen = 0 if ( !( defined $flen ) );
	my $self = $class->SUPER::new( $name, $ilen + $flen );
	$self->{'intlen'}  = $ilen;
	$self->{'fraclen'} = $flen;
	return $self;
}

sub process {
	my ( $self, $data ) = @_;

	$data =~ s/\s+//g;
	my $flen = $self->{'fraclen'};
	return $data if $data eq '';

	if ( $data !~ /\./ ) {
		$data /= 10**$flen;
	}
	return sprintf( "%.${flen}f", $data );
}

1;

=head1 NAME

oEdtk::FPField - fixed-point numeric field

=head1 SYNOPSIS

    use oEdtk::FPField;

    my $field = oEdtk::FPField->new('MONTANT', 8, 2);
    print $field->process('00012345'), "\n";   # '123.45'

=head1 DESCRIPTION

An C<oEdtk::Field> subclass for fixed-point numbers. The field is described by
an integer length and a fractional length, and C<process> renders the value
with exactly the requested number of decimals.

=head1 METHODS

=head2 new

    my $field = oEdtk::FPField->new($name, $ilen, $flen);

Construct a field whose byte length is C<$ilen + $flen>. C<$flen> defaults to
C<0>.

=head2 process

    my $value = $field->process($data);

Strip the blanks from C<$data>; an empty value returns C<''>. A value without a
decimal point is scaled down by C<10**$flen>, then formatted with C<$flen>
decimals.

=head1 AUTHOR

The oEdtk team.

=cut
