use 5.008;
use strict;
use warnings;

package Types::ReadOnly;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Type::Tiny 0.022 ();
use Types::Standard qw( Any Dict );
use Type::Utils;
use Type::Library -base, -declare => qw( ReadOnly Locked );

use Scalar::Util qw( reftype blessed );

sub _dclone($) {
	require Storable;
	no warnings 'redefine';
	*_dclone = \&Storable::dclone;
	goto &Storable::dclone;
}

my %skip = map { $_ => 1 } qw/CODE GLOB/;
sub _make_readonly {
	my (undef, $dont_clone) = @_;
	if (my $reftype = reftype $_[0] and not blessed($_[0]) and not &Internals::SvREADONLY($_[0])) {
		$_[0] = _dclone($_[0]) if !$dont_clone && &Internals::SvREFCNT($_[0]) > 1 && !$skip{$reftype};
		&Internals::SvREADONLY($_[0], 1);
		if ($reftype eq 'SCALAR' || $reftype eq 'REF') {
			_make_readonly(${ $_[0] }, 1);
		}
		elsif ($reftype eq 'ARRAY') {
			_make_readonly($_) for @{ $_[0] };
		}
		elsif ($reftype eq 'HASH') {
			&Internals::hv_clear_placeholders($_[0]);
			_make_readonly($_) for values %{ $_[0] };
		}
	}
	Internals::SvREADONLY($_[0], 1);
	return;
}

our %READONLY_REF_TYPES = (HASH => 1, ARRAY => 1, SCALAR => 1, REF => 1);

declare ReadOnly,
	bless     => 'Type::Tiny::Wrapper',
	pre_check => sub
	{
		$READONLY_REF_TYPES{reftype($_)} and &Internals::SvREADONLY($_);
	},
	inlined_pre_check => sub
	{
		return (
			"\$Types::ReadOnly::READONLY_REF_TYPES{Scalar::Util::reftype($_)}",
			"&Internals::SvREADONLY($_)",
		);
	},
	post_coerce => sub
	{
		_make_readonly($_);
		return $_;
	},
	inlined_post_coerce => sub
	{
		"do { Types::ReadOnly::_make_readonly($_); $_ }";
	};

my $_FIND_KEYS = sub {
	my ($dict) = grep {
		$_->is_parameterized
			and $_->has_parent
			and $_->parent->strictly_equals(Dict)
	} $_[0], $_[0]->parents;
	return unless $dict;
	return if ref($dict->parameters->[-1]) eq q(HASH);
	my @keys = sort keys %{ +{ @{ $dict->parameters } } };
	return unless @keys;
	\@keys;
};

# Stolen from Hash::Util 0.15.
# In earlier versions, of Hash::Util, there is only a hashref_unlocked
# function, which happens to be very broken. :-/
sub _hashref_locked
{
	my $hash=shift;
	Internals::SvREADONLY(%$hash);
}

declare Locked,
	bless     => 'Type::Tiny::Wrapper',
	pre_check => sub
	{
		return unless reftype($_) eq 'HASH';
		return unless &Internals::SvREADONLY($_);
		
		my $type    = shift;
		my $wrapped = $type->wrapped;
		
		if (my $KEYS = $wrapped->$_FIND_KEYS) {
			require Hash::Util;
			my $keys  = join "*#*", @$KEYS;
			my $legal = join "*#*", sort(&Hash::Util::legal_keys($_));
			return if $keys ne $legal;
		}
		
		return !!1;
	},
	inlined_pre_check => sub
	{
		my @r;
		push @r, qq[Scalar::Util::reftype($_) eq 'HASH'];
		push @r, qq[&Internals::SvREADONLY($_)];
		
		my $type    = $_[0];
		my $wrapped = $type->wrapped;
		
		if (my $KEYS = $wrapped->$_FIND_KEYS) {
			require B;
			require Hash::Util;
			push @r, B::perlstring(join "*#*", @$KEYS)
				.qq[ eq join("*#*", sort(&Hash::Util::legal_keys($_)))||''];
		}
		
		return @r;
	},
	post_coerce => sub
	{
		require Hash::Util;
		
		my $type    = shift;
		my $wrapped = $type->wrapped;
		
		&Hash::Util::unlock_hash($_);
		&Hash::Util::lock_keys($_, @{ $wrapped->$_FIND_KEYS || [] });
		return $_;
	},
	inlined_post_coerce => sub
	{
		require Hash::Util;
		
		my $type    = shift;
		my $wrapped = $type->wrapped;
		
		my $qkeys = '';
		if (my $KEYS = $wrapped->$_FIND_KEYS) {
			require B;
			$qkeys = join q[,], '', map B::perlstring($_), @$KEYS;
		}
		
		"&Hash::Util::unlock_hash($_); &Hash::Util::lock_keys($_ $qkeys); $_;";
	};

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Types::ReadOnly - type constraints and coercions for read-only data structures and locked hashes

=head1 SYNOPSIS

   has foo => (is => 'ro', isa => ReadOnly[ArrayRef], coerce => 1);

=head1 DESCRIPTION

This is a type constraint library for write-restricted references.

This module is built with L<Type::Tiny>, which means that you can use it
with L<Moo>, L<Mouse>, L<Moose>, or none of the above.

=head2 Type Constraints

This library provides the following type constraints:

=over

=item C<< ReadOnly >>

A type constraint for references to read-only scalars, arrays and
hashes. Values don't necessarily need to be deeply read-only to
pass the type check.

This type constraint I<< only works when it is parameterized >>.

This type constraint inherits coercions from its parameter, and
makes the result read-only (deeply).

=item C<< Locked >>

A type constraint for hashrefs with locked keys (see L<Hash::Util>).

This type constraint I<< only works when it is parameterized with 
C<HashRef> or a hashref-like type constraint >>. For example
C<< Locked[HashRef] >> or C<< Locked[ Map[ IpAddr, HostName ] ] >>.

When parameterized with a C<Dict> type constraint (see L<Types::Standard>),
it will use the C<Dict> type as the authoritative list of keys that the
hashref should be locked with, unless the Dict includes a slurpy parameter
(e.g. C<< Dict[foo => Int, slurpy HashRef[Num]] >>).

This type constraint inherits coercions from its parameter, and
applies C<lock_ref_keys> to the result.

=back

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

