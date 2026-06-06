package Zuzu::Error;

use utf8;

our $VERSION = '0.001005';

use overload '""' => sub { $_[0]->as_string }, fallback => 1;

use Moo;

has 'message' => ( is => 'rw' );
has 'file' => ( is => 'rw' );
has 'line' => ( is => 'rw' );
has 'code' => ( is => 'rw' );

sub _normalize_args {
	my ( $class, @args ) = @_;

	if ( @args == 1 and ref($args[0]) eq 'HASH' ) {
		return %{ $args[0] };
	}

	return @args;
}

sub _build_with_default_code {
	my ( $class, $default_code, @args ) = @_;

	my %ctor = $class->_normalize_args(@args);
	$ctor{code} = $default_code if !defined $ctor{code} or $ctor{code} eq '';

	return %ctor;
}

sub new_compile {
	my ( $class, @args ) = @_;

	require Zuzu::Error::Compile;

	return Zuzu::Error::Compile->new(
		$class->_build_with_default_code( 'E_COMPILE_GENERIC', @args )
	);
}

sub new_runtime {
	my ( $class, @args ) = @_;

	require Zuzu::Error::Runtime;

	return Zuzu::Error::Runtime->new(
		$class->_build_with_default_code( 'E_RUNTIME_GENERIC', @args )
	);
}

sub kind { 'Error' }

sub as_struct {
	my ( $self ) = @_;

	return {
		kind => $self->kind,
		code => $self->code,
		message => $self->message,
		file => ( defined $self->file ? $self->file : '<unknown>' ),
		line => ( defined $self->line ? 0 + $self->line : 0 ),
	};
}

sub as_string {
	my ($self) = @_;

	my $loc = defined $self->file ? ( $self->file // '<unknown>' ) : '<unknown>';
	my $ln  = defined $self->line ? $self->line : '?';
	my $code = defined $self->code ? $self->code : 'E_UNKNOWN';

	return sprintf( "%s[%s]: %s at %s:%s", $self->kind, $code, $self->message, $loc, $ln );
}

=pod

=head1 NAME

Zuzu::Error - base structured error object for Zuzu

=head1 DESCRIPTION

Provides shared message/location attributes and string formatting for all
Zuzu error classes.

Most callers should construct a subclass via C<new_compile> or
C<new_runtime>, which return C<Zuzu::Error::Compile> and
C<Zuzu::Error::Runtime> objects respectively.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

None.

=head1 ATTRIBUTES

=head2 message

Type: B<Str>.

Human-readable error message.

=head2 file

Type: B<Maybe[Str]>.

Source filename used for diagnostics.

=head2 line

Type: B<Int>.

1-based source line number used for diagnostics.

=head2 code

Type: B<Str>.

Machine-readable stable error code.

=head1 METHODS

=head2 new_compile

Creates and returns a C<Zuzu::Error::Compile> object.

=head2 new_runtime

Creates and returns a C<Zuzu::Error::Runtime> object.

=head2 kind

Returns the error category label.

The base implementation returns C<Error>. Subclasses override this.

=head2 as_struct

Returns machine-readable metadata as a hash reference.

=head2 as_string

Formats the error as a single diagnostic string.

=head1 SEE ALSO

L<Zuzu::Error::Compile>, L<Zuzu::Error::Runtime>.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Error >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
