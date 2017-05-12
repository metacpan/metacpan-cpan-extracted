use 5.008;
use strict;
use warnings;

package Type::Tiny::Wrapped;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Scalar::Util 'weaken';
use Type::Tiny 0.022 ();
use base 'Type::Tiny';

sub wrapper             { $_[0]{wrapper} }
sub wrapped             { $_[0]{parent} }
sub pre_check           { $_[0]{wrapper}{pre_check} }
sub pre_coerce          { $_[0]{wrapper}{pre_coerce} }
sub post_check          { $_[0]{wrapper}{post_check} }
sub post_coerce         { $_[0]{wrapper}{post_coerce} }
sub inlined_pre_check   { $_[0]{wrapper}{inlined_pre_check} }
sub inlined_pre_coerce  { $_[0]{wrapper}{inlined_pre_coerce} }
sub inlined_post_check  { $_[0]{wrapper}{inlined_post_check} }
sub inlined_post_coerce { $_[0]{wrapper}{inlined_post_coerce} }

sub _build_compiled_check {
	my $self = shift;
	
	return Eval::TypeTiny::eval_closure(
		source      => sprintf('sub ($) { %s }', $self->inline_check('$_[0]')),
		description => sprintf("compiled check '%s'", $self),
	) if $self->can_be_inlined;
	
	my $pre  = $self->pre_check;
	my $orig = $self->wrapped->compiled_check(@_);
	my $post = $self->post_check;
	
	return $orig unless $pre || $post;
	
	weaken $self;
	return sub {
		local $_ = $_[0];
		return if defined($pre) && !$pre->($self, @_);
		return if !$orig->(@_);
		return if defined($post) && !$post->($self, @_);
		return !!1;
	};
}

sub _strict_check {
	my $self = shift;
	local $_ = $_[0];
	
	my $pre  = $self->pre_check;
	my $post = $self->post_check;
	
	return if defined($pre) && !$pre->($self, @_);
	return if !$self->wrapped->_strict_check(@_);
	return if defined($post) && !$post->($self, @_);
	
	return !!1;
}

sub is_subtype_of {
	my $self = shift;
	$self->wrapper->is_a_type_of(@_) or $self->SUPER::is_subtype_of(@_);
}

sub inline_check {
	my $self  = shift;
	local $_ = (my $var = $_[0]);
	
	Type::Tiny::_croak('Cannot inline type constraint check for "%s"', $self)
		unless $self->can_be_inlined;
	
	my @r;
	if (my $pre = $self->inlined_pre_check) {
		push @r, $pre->($self, $var);
	}
	push @r, $self->wrapped->inline_check($var);
	if (my $post = $self->inlined_post_check) {
		push @r, $post->($self, $var);
	}
	
	my $r = join " && " => map { /[;{}]/ ? "do { $_ }" : "($_)" } @r;
	return @r==1 ? $r : "($r)";
}

sub can_be_inlined {
	my $self = shift;
	return if $self->pre_check && ! $self->inlined_pre_check;
	return if $self->post_check && ! $self->inlined_post_check;
	return $self->wrapped->can_be_inlined;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Tiny::Wrapped - a type constraint that has been wrapped with a Type::Tiny::Wrapper

=head1 DESCRIPTION

This is a subclass of L<Type::Tiny> used internally by L<Types::ReadOnly>.
The API is not considered stable; it may change in response to
Type::ReadOnly's needs.

=head2 Attributes

It provides the following additional attributes.

=over

=item C<wrapper>

The C<Type::Tiny::Wrapper> that created this Type::Tiny::Wrapped type
constraint. Required.

=item C<wrapped>

The Type::Tiny object which has been wrapped. This is just an alias for
C<parent> really.

=item C<pre_check>, C<pre_coerce>, C<post_check>, C<post_coerce>,
C<inlined_pre_check>, C<inlined_pre_coerce>, C<inlined_post_check>,
C<inlined_post_coerce>

Delegated to C<wrapper>.

=back

=begin trustme

=item can_be_inlined
=item inline_check
=item is_subtype_of

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

