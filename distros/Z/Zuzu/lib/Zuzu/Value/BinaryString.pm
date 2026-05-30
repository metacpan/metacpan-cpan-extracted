package Zuzu::Value::BinaryString;

use utf8;

our $VERSION = '0.001002';

use Moo;
use Encode ();

use overload
	'""' => sub { $_[0]->bytes // '' },
	fallback => 1;

has 'bytes' => ( is => 'rw', default => sub { '' } );

sub BUILD {
	my ( $self ) = @_;

	my $bytes = $self->bytes // '';
	utf8::encode( $bytes ) if utf8::is_utf8( $bytes );
	$self->bytes( $bytes );

	return;
}

sub from_utf8_string {
	my ( $class, $text ) = @_;
	$text //= '';
	my $bytes = Encode::encode( 'UTF-8', $text, Encode::FB_CROAK );

	return $class->new( bytes => $bytes );
}

sub byte_length {
	my ( $self ) = @_;

	return length( $self->bytes // '' );
}

sub is_ascii {
	my ( $self ) = @_;
	my $bytes = $self->bytes // '';

	return $bytes !~ /[^\x00-\x7F]/ ? 1 : 0;
}

sub to_utf8_string {
	my ( $self ) = @_;
	my $bytes = $self->bytes // '';

	return Encode::decode( 'UTF-8', $bytes, Encode::FB_CROAK );
}

sub to_String {
	my ( $self ) = @_;

	return $self->bytes // '';
}

sub to_Boolean {
	my ( $self ) = @_;

	return $self->byte_length ? 1 : 0;
}

sub _stable_key {
	my ( $self ) = @_;
	my $bytes = $self->bytes // '';

	return unpack( 'H*', $bytes );
}

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Value::BinaryString >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
