#!/usr/bin/perl

package Tie::RefHash::Weak;
use base qw/Tie::RefHash Exporter/;

use strict;
use warnings;

use warnings::register;

use overload ();

use B qw/svref_2object CVf_CLONED/;

our $VERSION = 0.09;
our @EXPORT_OK = qw 'fieldhash fieldhashes';
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use Scalar::Util qw/weaken reftype/;
use Variable::Magic qw/wizard cast getdata/;

my $wiz = wizard free => \&_clear_weakened_sub, data => \&_add_magic_data;

sub _clear_weakened_sub {
	my ( $key, $objs ) = @_;
	local $@;
	foreach my $self ( grep { defined } @{ $objs || [] } ) {
		eval { $self->_clear_weakened($key) }; # support subclassing
	}
}

sub _add_magic_data {
	my ( $key, $objects ) = @_;
	$objects;
}

sub _clear_weakened {
	my ( $self, $key ) = @_;

	$self->DELETE( $key );
}

sub STORE {
	my($s, $k, $v) = @_;

	if (ref $k) {
		# make sure we use the same function that RefHash is using for ref keys
		my $kstr = Tie::RefHash::refaddr($k);
		my $entry = [$k, $v];

		weaken( $entry->[0] );

		my $objects;

		if ( reftype $k eq 'CODE' ) {
			unless ( svref_2object($k)->CvFLAGS & CVf_CLONED ) {
				warnings::warnif("Non closure code references never get garbage collected: $k");
			} else {
				$objects = &getdata ( $k, $wiz )
					or &cast( $k, $wiz, ( $objects = [] ) );
			}
		} else {
			$objects = &getdata( $k, $wiz )
				or &cast( $k, $wiz, ( $objects = [] ) );
		}

		@$objects = grep { defined } @$objects;

		unless ( grep { $_ == $s } @$objects ) {
			push @$objects, $s;
			weaken($objects->[-1]);
		}

		$s->[0]{$kstr} = $entry;
	}
	else {
		$s->[1]{$k} = $v;
	}

	$v;
}

sub fieldhash(\%) {
	tie %{$_[0]}, __PACKAGE__;
	return $_[0];
}

sub fieldhashes {
	tie %{$_}, __PACKAGE__ for @_;
	return @_;
}

__PACKAGE__

__END__

=pod

=head1 NAME

Tie::RefHash::Weak - A Tie::RefHash subclass with weakened references in the keys.

=head1 SYNOPSIS

	use Tie::RefHash::Weak;
	tie my %h, 'Tie::RefHash::Weak';

	# OR:

	use Tie::RefHash::Weak 'fieldhash';
	fieldhash my %h;

	{ # new scope
		my $val = "foo";

		$h{\$val} = "bar"; # key is weak ref
	
		print join(", ", keys %h); # contains \$val, returns regular reference
	}
	# $val goes out of scope, refcount goes to zero
	# weak references to \$val are now undefined

	keys %h; # no longer contains \$val

	# see also Tie::RefHash

=head1 DESCRIPTION

The L<Tie::RefHash> module can be used to access hashes by reference. This is
useful when you index by object, for example.

The problem with L<Tie::RefHash>, and cross indexing, is that sometimes the
index should not contain strong references to the objecs. L<Tie::RefHash>'s
internal structures contain strong references to the key, and provide no
convenient means to make those references weak.

This subclass of L<Tie::RefHash> has weak keys, instead of strong ones. The
values are left unaltered, and you'll have to make sure there are no strong
references there yourself.

=head1 FUNCTIONS

For compatibility with L<Hash::Util::FieldHash>, this module will, upon
request, export the following two functions. You may also write
C<use Tie::RefHash::Weak ':all'>.

=over 4

=item fieldhash %hash

This ties the hash and returns a reference to it.

=item fieldhashes \%hash1, \%hash2 ...

This ties each hash that is passed to it as a reference. It returns the
list of references in list context, or the number of hashes in scalar
context.

=back

=head1 THREAD SAFETY

L<Tie::RefHash> version 1.32 and above have correct handling of threads (with
respect to changing reference addresses). If your module requires
Tie::RefHash::Weak to be thread aware you need to depend on both
L<Tie::RefHash::Weak> and L<Tie::RefHash> version 1.32 (or later).

Version 0.02 and later of Tie::RefHash::Weak depend on a thread-safe version of
Tie::RefHash anyway, so if you are using the latest version this should already
be taken care of for you.

=head1 5.10.0 COMPATIBILITY

Due to a minor change in Perl 5.10.0 a bug in the handling of magic freeing was
uncovered causing segmentation faults.

This has been patched but not released yet, as of 0.08.

=head1 CAVEAT

You can use an LVALUE reference (such as C<\substr ...>) as a hash key, but
due to a bug in perl (see
L<http://rt.perl.org/rt3/Public/Bug/Display.html?id=46943>) it might not be 
possible to weaken a reference to it, in which case the hash element will 
never be deleted automatically.

=head1 AUTHORS

Yuval Kogman <nothingmuch@woobling.org>

some maintenance by Hans Dieter Pearcey <hdp@pobox.com>

=head1 COPYRIGHT & LICENSE

        Copyright (c) 2004 Yuval Kogman. All rights reserved
        This program is free software; you can redistribute
        it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Tie::RefHash>, L<Class::DBI> (the live object cache),
L<mg.c/Perl_magic_killbackrefs>

=cut
