use 5.008;
use strict;
use warnings;

package Type::Coercion::Wrapped;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use base 'Type::Coercion';
use Scalar::Util 'weaken';

sub _build_compiled_coercion {
	my $self = shift;
	
	return $self->SUPER::_build_compiled_coercion(@_)
		if $self->can_be_inlined;
	
	my $type = $self->type_constraint;
	my $pre  = $type->pre_coerce;
	my $orig = $self->SUPER::_build_compiled_coercion(@_);
	my $post = $type->post_coerce;
	
	return $orig unless $pre || $post;
	
	weaken $type;
	return sub {
		local $_ = $_[0];
		$_ = $pre->($type, $_) if defined($pre);
		$_ = $orig->($_);
		$_ = $post->($type, $_) if defined($post);
		return $_;
	};
}

my $counter = 0;
sub inline_coercion {
	my $self = shift;
	local $_ = (my $varname = $_[0]);
	
	my $tc   = $self->type_constraint;
	my $pre  = $tc && $tc->inlined_pre_coerce;
	my $post = $tc && $tc->inlined_post_coerce;
	
	my $code = '';
	if ($pre) {
		my $tmpvar = sprintf('$__TypeCoercionWrappedTmp%d', ++$counter);
		$code .= sprintf('my %s = do { no warnings; %s };', $tmpvar, $pre->($tc, $varname));
		$_ = $varname = $tmpvar;
	}
	
	do {
		my $tmpvar = sprintf('$__TypeCoercionWrappedTmp%d', ++$counter);
		$code .= sprintf('my %s = do { no warnings; %s };', $tmpvar, $self->SUPER::inline_coercion($varname));
		$_ = $varname = $tmpvar;
	};
	
	if ($post) {
		$code .= sprintf('do { no warnings; %s };', $post->($tc, $varname));
	}
	
	"do { no warnings; $code }";
}

sub can_be_inlined {
	my $self = shift;
	if (my $tc = $self->type_constraint) {
		return if $tc->pre_coerce && !$tc->inlined_pre_coerce;
		return if $tc->post_coerce && !$tc->inlined_post_coerce;
	}
	return $self->SUPER::can_be_inlined;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Type::Coercion::Wrapped - a coercion for a Type::Tiny::Wrapped type constraint

=head1 DESCRIPTION

This is a subclass of L<Type::Coercion> used internally by L<Types::ReadOnly>.
The API is not considered stable; it may change in response to
Type::ReadOnly's needs.

This subclass provides no additional attributes or methods.

=begin trustme

=item can_be_inlined
=item inline_coercion

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

