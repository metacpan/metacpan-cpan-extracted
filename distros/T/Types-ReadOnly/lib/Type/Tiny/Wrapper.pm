use 5.008;
use strict;
use warnings;

package Type::Tiny::Wrapper;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use base 'Type::Tiny';
use Scalar::Util 'weaken';

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	Type::Tiny::_croak("Type::Tiny::Wrapper types must not have a constraint!")
		unless $self->_is_null_constraint;
	return $self;
}

sub wrap {
	my $self = shift;
	my $type = Types::TypeTiny::to_TypeTiny($_[0]);
	require Type::Tiny::Wrapped;
	require Type::Coercion::Wrapped;
	my $wrapped = bless($type->create_child_type => 'Type::Tiny::Wrapped');
	$wrapped->{wrapper}      = $self;
	$wrapped->{display_name} = sprintf('%s[%s]', $self->display_name, $type->display_name);
	$wrapped->{coercion}   ||= 'Type::Coercion::Wrapped'->new(
		type_constraint   => $wrapped,
		type_coercion_map => $type->has_coercion
			? [ @{$type->coercion->type_coercion_map} ]
			: [ Types::Standard::Any(), q{ $_ } ],
	);
	bless($wrapped->{coercion} => 'Type::Coercion::Wrapped');
	return $wrapped;
}

my @FIELDS = qw/
	pre_check pre_coerce post_check post_coerce
	inlined_pre_check inlined_pre_coerce inlined_post_check inlined_post_coerce
/;
sub pre_check           { $_[0]{pre_check} }
sub pre_coerce          { $_[0]{pre_coerce} }
sub post_check          { $_[0]{post_check} }
sub post_coerce         { $_[0]{post_coerce} }
sub inlined_pre_check   { $_[0]{inlined_pre_check} }
sub inlined_pre_coerce  { $_[0]{inlined_pre_coerce} }
sub inlined_post_check  { $_[0]{inlined_post_check} }
sub inlined_post_coerce { $_[0]{inlined_post_coerce} }

sub child_type_class { +__PACKAGE__ }

sub create_child_type {
	my $self = shift;
	$self->SUPER::create_child_type(
		( map {
			exists($self->{$_}) ? ($_ => $self->{$_}) : ()
		} @FIELDS ),
		@_,
	);
}

sub has_constraint_generator { 1 }

sub constraint_generator {
	my $self = shift;
	weaken $self;
	return sub { $self->wrap(shift) };
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Tiny::Wrapper - a type constraint that is only useful when wrapping another type constraint

=head1 DESCRIPTION

This is a subclass of L<Type::Tiny> used internally by L<Types::ReadOnly>.
The API is not considered stable; it may change in response to
Type::ReadOnly's needs.

=head2 Attributes

It provides the following additional attributes.

=over

=item C<pre_check>, C<pre_coerce>, C<post_check>, C<post_coerce>.

Coderefs which fire on certain events. Each coderef is passed C<< $self >>
and the value being checked/coerced as parameters. The value being
checked/coerced is also available in C<< $_ >>.

For the check events, the coderef is expected to return false if the
value fails the check, and return true if checking the value should
proceed to the wrapped type constraint.

=item C<inlined_pre_check>, C<inlined_pre_coerce>, C<inlined_post_check>,
C<inlined_post_coerce>

Coderefs that can inline the pre/post check/coerce events.

Each coderef is passed C<< $self >> and the variable name to be
checked/coerced as parameters. The variable name is also available
in C<< $_ >>.

Expected to return a string of Perl code which evaluates to an
expression. Checks can alternatively return a list of such strings,
which will be joined by "&&".

=back

=head2 Method

=over

=item C<< wrap($other) >>

Wraps a type constraint and returns a L<Type::Tiny::Wrapped> object.

=back

=begin trustme

=item child_type_class
=item constraint_generator
=item create_child_type
=item has_constraint_generator
=item new
=item post_coerce

=end trustme

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Types-ReadOnly>.

=head1 SEE ALSO

L<Type::Tiny::Manual>, L<Hash::Util>, L<Const::Fast>, L<MooseX::Types::Ro>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

