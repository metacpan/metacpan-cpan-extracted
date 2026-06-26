package Zuzu::Token;

use utf8;

our $VERSION = '0.007000';

use Moo;

has 'type' => ( is => 'rw' );
has 'value' => ( is => 'rw' );
has 'file' => ( is => 'rw' );
has 'line' => ( is => 'rw' );
has 'col' => ( is => 'rw' );

sub is_type {
	my ( $self, $type ) = @_;

	return $self->type eq $type;
}

sub is_KW {
	my ( $self, $value ) = @_;

	return 0 if !$self->is_type('KW');

	return 1 if !defined $value;

	return ( $self->value // '' ) eq $value;
}

sub is_OP {
	my ( $self, $value ) = @_;

	return 0 if !$self->is_type('OP');

	return 1 if !defined $value;

	return ( $self->value // '' ) eq $value;
}

sub is_IDENT { $_[0]->is_type('IDENT') }

sub is_NUMBER { $_[0]->is_type('NUMBER') }

sub is_STRING { $_[0]->is_type('STRING') }

sub is_BOOL { $_[0]->is_type('BOOL') }

sub is_NULL { $_[0]->is_type('NULL') }

sub is_EMPTY_SET { $_[0]->is_type('EMPTY_SET') }

sub is_REGEXP { $_[0]->is_type('REGEXP') }

sub is_EOF { $_[0]->is_type('EOF') }

=pod

=head1 NAME

Zuzu::Token - token object produced by the lexer

=head1 DESCRIPTION

Carries token type, value, and source location used by the parser and
diagnostics.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

None.

=head1 ATTRIBUTES

=head2 type

Type: B<Str>.

Token category name (for example C<IDENT>, C<NUMBER>, or C<OP>).

=head2 value

Type: B<Any>.

Literal payload or symbol text associated with C<type>.

=head2 file

Type: B<Maybe[Str]>.

Source filename used for diagnostics.

=head2 line

Type: B<Int>.

1-based source line number used for diagnostics.

=head2 col

Type: B<Int>.

1-based source column number used for diagnostics.

=head1 METHODS

=head2 is_type

Returns true when C<type> matches the supplied type string.

=head2 is_KW

Returns true when this token is a C<KW> token.

When a value argument is supplied, also requires C<value> to match.

=head2 is_OP

Returns true when this token is an C<OP> token.

When a value argument is supplied, also requires C<value> to match.

=head2 is_IDENT

Returns true when this token is an C<IDENT> token.

=head2 is_NUMBER

Returns true when this token is an C<NUMBER> token.

=head2 is_STRING

Returns true when this token is an C<STRING> token.

=head2 is_BOOL

Returns true when this token is an C<BOOL> token.

=head2 is_NULL

Returns true when this token is an C<NULL> token.

=head2 is_EMPTY_SET

Returns true when this token is an C<EMPTY_SET> token.

=head2 is_EOF

Returns true when this token is an C<EOF> token.

=head1 SEE ALSO

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Token >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
