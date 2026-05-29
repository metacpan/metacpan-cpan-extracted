package Zuzu::Weak;

use utf8;
use strict;
use warnings;

our $VERSION = '0.001000';

use Exporter qw( import );
use Scalar::Util qw( blessed weaken );

our @EXPORT_OK = qw(
	is_weakable_value
	make_weak_value
	resolve_weak_value
	slot_value
	store_value
);

sub is_weakable_value {
	my ( $value ) = @_;

	return 0 if !defined $value;
	return 0 if !ref $value;
	return 0 if ref($value) eq 'Regexp';

	if ( blessed($value) ) {
		return 0 if $value->isa('Zuzu::Value::Boolean');
		return 0 if $value->isa('Zuzu::Value::BinaryString');
		return 0 if $value->isa('Zuzu::Value::Regexp');
	}

	return 1;
}

sub make_weak_value {
	my ( $value ) = @_;

	return $value;
}

sub resolve_weak_value {
	my ( $value ) = @_;

	return $value;
}

sub _assert_storage_ref {
	my ( $slot_ref, $context ) = @_;

	my $ok = eval {
		my $unused = $$slot_ref;
		1;
	};
	die "$context requires a scalar reference" if !$ok;

	return;
}

sub store_value {
	my ( $slot_ref, $value, $is_weak ) = @_;

	_assert_storage_ref( $slot_ref, 'Weak storage' )
		if ref($slot_ref) ne 'SCALAR';

	$$slot_ref = $value;
	weaken($$slot_ref)
		if $is_weak && is_weakable_value($value);

	return $value;
}

sub slot_value {
	my ( $slot_ref ) = @_;

	_assert_storage_ref( $slot_ref, 'Weak storage read' )
		if ref($slot_ref) ne 'SCALAR';

	return $$slot_ref;
}

1;

=pod

=head1 NAME

Zuzu::Weak - weak-reference classification helpers

=head1 DESCRIPTION

Provides the shared Perl-side classification for values that may later
be stored through weak-storage rules. The classification is based on
ZuzuScript semantics rather than host implementation details.

=head1 FUNCTIONS

=head2 is_weakable_value( $value )

Returns true for reference-capable Zuzu values and false for scalar Zuzu
values. C<null>, booleans, numbers, strings, binary strings, and
regular expressions are scalar values and are never weakened.

=head2 make_weak_value( $value )

Compatibility helper for code that needs a value-level API. Perl weak
storage must weaken the target scalar itself, so new storage code should
use C<store_value> instead.

=head2 resolve_weak_value( $value )

Returns the value unchanged. Perl weak storage resolves through the
target scalar itself.

=head2 store_value( $slot_ref, $value, $is_weak )

Stores C<$value> into C<$slot_ref>. When C<$is_weak> is true and the
value is weakable from ZuzuScript's perspective, weakens the stored
reference in that slot.

=head2 slot_value( $slot_ref )

Reads a storage scalar. A dead Perl weak reference naturally reads as
C<undef>, matching the core weak-storage representation.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Weak >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
