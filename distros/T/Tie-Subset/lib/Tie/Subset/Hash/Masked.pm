#!perl
package Tie::Subset::Hash::Masked;
use warnings;
use strict;
use warnings::register;
use Carp;

# For AUTHOR, COPYRIGHT, AND LICENSE see the bottom of this file

=head1 Name

Tie::Subset::Hash::Masked - Tie a hash to mask some of its keys

=head1 Synopsis

 use Tie::Subset::Hash::Masked;
 use Data::Dumper;
 my %hash = ( foo=>11, bar=>22, quz=>33 );
 tie my %masked, 'Tie::Subset::Hash::Masked', \%hash, ['bar','quz'];
 print Dumper(\%masked);  # shows only { foo => 11 }
 $masked{baz}++;          # adds this key to %masked and %hash

=head1 Description

This class for tied hashes provides a masked "view" of a hash.

=over

=cut

our $VERSION = '0.02';

=item C<tie>ing

 tie my %masked, 'Tie::Subset::Hash::Masked', \%hash, \@mask;

You must specify which keys from the original hash should be masked
in the tied hash. (Keys that do not yet exist in the original hash
may also be specified.)

=cut

sub TIEHASH {  ## no critic (RequireArgUnpacking)
	@_==3 or croak "bad number of arguments to tie";
	my ($class, $hash, $mask) = @_;
	ref $hash eq 'HASH' or croak "must provide hashref to tie";
	ref $mask eq 'ARRAY' or croak "must provide key list to mask";
	for (@$mask) { croak "bad hash key '$_'" if ref; croak "bad hash key undef" if !defined }
	my $self = { hash => $hash, mask => { map {$_=>1} @$mask } };
	return bless $self, $class;
}

=item Fetching

If the key is masked, returns nothing (undef), otherwise, the value
from the underlying hash is returned.

=cut

sub FETCH {
	my ($self,$key) = @_;
	return if exists $self->{mask}{$key};
	return $self->{hash}{$key};
}

=item Storing

If the key is masked, the operation is ignored and a warning issued,
otherwise, the new value will be stored in the underlying hash.

=cut

sub STORE {
	my ($self,$key,$val) = @_;
	if (not exists $self->{mask}{$key}) {
		return $self->{hash}{$key} = $val;
	} # else
	warnings::warnif("assigning to masked key '$key' not (yet) supported in ".ref($self).", ignoring");
	return;
}

=item C<exists>

Will return true only if the key exists in the underlying hash I<and>
the key is not masked.

=cut

sub EXISTS {
	my ($self,$key) = @_;
	# need to write this in this slightly strange way because otherwise
	# the code coverage tool isn't picking it up correctly...
	if ( !exists $self->{mask}{$key} && exists $self->{hash}{$key} )
		{ return !!1 } else { return !!0 }
}

=item Iterating (C<each>, C<keys>, etc.)

Only keys that exist in the underlying hash I<and> that aren't masked
are iterated over. The iterator of the underlying hash is utilized,
so iterating over the tied hash will affect the state of the iterator
of the underlying hash.

=cut

sub FIRSTKEY {
	my ($self) = @_;
	my $dummy = keys %{$self->{hash}};  # reset iterator
	return $self->NEXTKEY;
}
sub NEXTKEY {
	my ($self,$lkey) = @_;
	my $next;
	SEEK: {
		$next = each %{$self->{hash}};
		return unless defined $next;
		redo SEEK if exists $self->{mask}{$next};
	}
	return $next;
}

=item C<delete>ing

If the key is masked, the operation is ignored and a warning issued,
otherwise, the key will be deleted from the underlying hash.

=cut

sub DELETE {
	my ($self,$key) = @_;
	if (not exists $self->{mask}{$key}) {
		return delete $self->{hash}{$key};
	} # else
	warnings::warnif("deleting masked key '$key' not (yet) supported in ".ref($self).", ignoring");
	return;
}

=item Clearing

Not (yet) supported (because it is ambiguous whether this operation
should delete keys from the underlying hash or not). Attempting to
clear the tied hash currently does nothing and causes a warning
to be issued.

A future version of this module may lift this limitation (if a
useful default behavior exists).

=cut

sub CLEAR {
	my ($self) = @_;
	warnings::warnif("clearing of ".ref($self)." not (yet) supported, ignoring");
	return;
}

sub SCALAR {
	my ($self) = @_;
	# I'm not sure why the following counts as two statements in the coverage tool
	# uncoverable branch true
	# uncoverable statement count:2
	return scalar %{$self->{hash}} if $] lt '5.026';
	my %keys = map {$_=>1} keys %{$self->{hash}};
	delete @keys{ keys %{$self->{mask}} };
	return scalar keys %keys;
}

sub UNTIE {
	my ($self) = @_;
	$self->{hash} = undef;
	$self->{mask} = undef;
	return;
}

1;
__END__

=back

=head1 See Also

L<Tie::Subset::Hash>

L<Tie::Subset/"See Also">

=head1 Author, Copyright, and License

Copyright (c) 2023 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut
