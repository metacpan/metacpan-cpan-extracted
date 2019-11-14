use 5.008;
use strict;
use warnings;

package Types::ReadOnly;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Type::Tiny 1.006000 ();
use Type::Coercion ();
use Types::Standard qw( Any Dict HashRef Ref );
use Type::Library -base, -declare => qw( ReadOnly Locked );

use Scalar::Util qw( reftype blessed refaddr );

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
		if ($reftype eq 'SCALAR' or $reftype eq 'REF') {
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

__PACKAGE__->meta->add_type({
	name        => 'ReadOnly',
	parent      => Ref,
	constraint  => sub {
		my $r = reftype($_);
		($r eq 'HASH' or $r eq 'ARRAY' or $r eq 'SCALAR' or $r eq 'REF') and &Internals::SvREADONLY($_);
	},
	constraint_generator => sub {
		my ($parameter) = @_ or return $Type::Tiny::parameterize_type;
		$parameter->compiled_check; # only need this because parent constraint (i.e. ReadOnly) is automatically checked
	},
	inlined     => sub {
		my ($self, $varname) = @_;
		return (
			sprintf('do { my $r = Scalar::Util::reftype(%s); $r eq "HASH" or $r eq "ARRAY" or $r eq "SCALAR" or $r eq "REF" }', $varname),
			sprintf('&Internals::SvREADONLY(%s)', $varname),
		);
	},
	inline_generator => sub {
		my ($parameter) = @_ or return $Type::Tiny::parameterize_type;
		return unless $parameter->can_be_inlined;
		sub {
			my ($child, $varname) = @_;
			my $me = $child->parent;
			return ($me->inline_check($varname), $parameter->inline_check($varname));
		};
	},
	coercion => [
		Ref ,=> 'do { Types::ReadOnly::_make_readonly(my $ro = $_); $ro }',
	],
	coercion_generator => sub {
		my ($me, $child) = @_;
		my $parameter = $child->type_parameter;
		my @extra;
		if ($parameter->has_coercion) {
			my @map = @{ $parameter->coercion->type_coercion_map };
			while (@map) {
				my ($t, $code) = splice @map, 0, 2;
				if (Types::TypeTiny::CodeLike->check($code)) {
					push @extra, $t, sub {
						my $coerced = $code->(@_);
						Types::ReadOnly::_make_readonly($coerced);
						$coerced;
					};
				}
				else {
					push @extra, $t, sprintf('do { my $coerced = %s; Types::ReadOnly::_make_readonly($coerced); $coerced }', $code);
				}
			}
		}
		bless(
			{ type_coercion_map => [
				$parameter => 'do { Types::ReadOnly::_make_readonly(my $ro = $_); $ro }',
				@extra,
			] },
			'Type::Coercion'
		);
	},
});

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
sub _hashref_locked { &Internals::SvREADONLY($_[0]) }

__PACKAGE__->meta->add_type({
	name        => 'Locked',
	parent      => Ref['HASH'],
	constraint  => sub {
		my $r = reftype($_);
		&Internals::SvREADONLY($_);
	},
	constraint_generator => sub {
		my ($parameter) = @_ or return $Type::Tiny::parameterize_type;
		my $pchk = $parameter->compiled_check;
		my $KEYS = $parameter->$_FIND_KEYS or return $pchk;
		my $keys = join "*#*", @$KEYS;
		sub {
			my $legal = join "*#*", sort(&Hash::Util::legal_keys($_));
			return if $keys ne $legal;
			goto $pchk;
		};
	},
	inlined     => sub {
		my ($self, $varname) = @_;
		my $r = Ref['HASH'];
		return (
			$r->inline_check($varname),
			sprintf('&Internals::SvREADONLY(%s)', $varname),
		);
	},
	inline_generator => sub {
		require Hash::Util;
		my ($parameter) = @_ or return $Type::Tiny::parameterize_type;
		return unless $parameter->can_be_inlined;
		my $KEYS = $parameter->$_FIND_KEYS;
		my $keys = join "*#*", @{ $KEYS || [] };
		sub {
			my ($child, $varname) = @_;
			my @extras;
			if ($keys) {
				require Hash::Util;
				push @extras, sprintf('%s eq join("*#*", sort(&Hash::Util::legal_keys(%s)))', B::perlstring($keys), $varname);
			}
			(undef, @extras, $parameter->inline_check($varname));
		};
	},
	coercion => [
		Ref['HASH'] , => 'do { Types::ReadOnly::_make_readonly(my $ro = $_); $ro }',
	],
	coercion_generator => sub {
		require Hash::Util;
		my ($me, $child) = @_;
		my $parameter = $child->type_parameter;
		my $KEYS = $parameter->$_FIND_KEYS;
		my $qkeys = $KEYS ? join(q[,], '', map B::perlstring($_), @$KEYS) : '';
		my @extra;
		if ($parameter->has_coercion) {
			my @map = @{ $parameter->coercion->type_coercion_map };
			while (@map) {
				my ($t, $code) = splice @map, 0, 2;
				if (Types::TypeTiny::CodeLike->check($code)) {
					push @extra, $t, sub {
						my $coerced = $code->(@_);
						&Hash::Util::unlock_hash($coerced);
						&Hash::Util::lock_hash($coerced, @{$KEYS||[]});
						$coerced;
					};
				}
				else {
					push @extra, $t, sprintf('do { my $coerced = %s; &Hash::Util::unlock_hash($coerced); &Hash::Util::lock_keys($coerced %s); $coerced }', $code, $qkeys);
				}
			}
		}
		bless(
			{ type_coercion_map => [
				$parameter => sprintf('do { my $coerced = $_; &Hash::Util::unlock_hash($coerced); &Hash::Util::lock_keys($coerced %s); $coerced }', $qkeys),
				@extra,
			] },
			'Type::Coercion'
		);
	},
});


# This comparator allows Locked[Foo] to be seen as a child of Foo, and not
# just a child of Locked. It's probably not foolproof.
#
my $comparator;
$comparator = sub {
	my $A  = shift->find_constraining_type;
	my $B  = shift->find_constraining_type;
	my $RO = __PACKAGE__->get_type('ReadOnly');
	my $L  = __PACKAGE__->get_type('Locked');
		
	my $Aprime = $A->find_parent(sub {
		$_->is_parameterized and
		$_->has_parent and
		$_->parent->strictly_equals($L) || $_->parent->strictly_equals($RO)
	});
	
	if ($Aprime) {
		my $param = $Aprime->type_parameter->find_constraining_type;
		if ($param->is_a_type_of($B)) {
			return Type::Tiny::CMP_SUBTYPE();
		}
	}
	
	return Type::Tiny::CMP_UNKNOWN() if @_;
	
	my $r = $comparator->($B, $A, 1);
	return  $r if ($r eq Type::Tiny::CMP_EQUIVALENT());
	return -$r if ($r eq Type::Tiny::CMP_SUPERTYPE() || $r eq Type::Tiny::CMP_SUBTYPE());
	
	Type::Tiny::CMP_UNKNOWN();
};

push @Type::Tiny::CMP, $comparator;

__PACKAGE__->meta->make_immutable;


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

This software is copyright (c) 2013, 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

