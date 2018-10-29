#!perl
package Tie::Subset::Hash;
use warnings;
use strict;
use warnings::register;
use Carp;

# For AUTHOR, COPYRIGHT, AND LICENSE see the bottom of this file

=head1 Name

Tie::Subset::Hash - Tie a hash to a subset of another hash

=head1 Synopsis

 use Tie::Subset::Hash;
 my %hash = ( foo=>11, bar=>22, quz=>33 );
 tie my %subset, 'Tie::Subset::Hash', \%hash, ['bar','quz'];
 print "$subset{bar}\n";  # prints "22"
 $subset{quz}++;          # modifies $hash{quz}

=head1 Description

This class for tied hashes provides a "view" of a subset of a hash.

=over

=cut

our $VERSION = '0.01';

=item C<tie>ing

 tie my %subset, 'Tie::Subset::Hash', \%hash, \@keys;

You must specify which subset of keys from the original hash can
be accessed via the tied hash. (Keys that do not yet exist in the
original hash may be specified.)

=cut

sub TIEHASH {  ## no critic (RequireArgUnpacking)
	@_==3 or croak "bad number of arguments to tie";
	my ($class, $hash, $keys) = @_;
	ref $hash eq 'HASH' or croak "must provide hashref to tie";
	ref $keys eq 'ARRAY' or croak "must provide key list to tie";
	for (@$keys) { croak "bad hash key '$_'" if ref || !defined }
	my $self = { hash => $hash, keys => { map {$_=>1} @$keys } };
	return bless $self, $class;
}

=item Fetching

If the key is in the subset, the value from the underlying hash is
returned, otherwise returns nothing (undef).

=cut

sub FETCH {
	my ($self,$key) = @_;
	return unless exists $self->{keys}{$key};
	return $self->{hash}{$key};
}

=item Storing

If the key is in the subset, the new value will be stored in the
underlying hash, otherwise the operation is ignored and a warning
issued.

=cut

sub STORE {
	my ($self,$key,$val) = @_;
	if (exists $self->{keys}{$key}) {
		return $self->{hash}{$key} = $val;
	} # else
	warnings::warnif("assigning to unknown key '$key' not (yet) supported in ".ref($self).", ignoring");
	return;
}

=item C<exists>

Will return true only if the key is in the subset I<and> it exists
in the underlying hash.

=cut

sub EXISTS {
	my ($self,$key) = @_;
	return exists $self->{keys}{$key} && exists $self->{hash}{$key};
}

=item Iterating (C<each>, C<keys>, etc.)

Only keys that exist are both in the subset I<and> the underlying
hash are iterated over.

=cut

sub FIRSTKEY {
	my ($self) = @_;
	my $dummy = keys %{$self->{keys}};  # reset iterator
	return $self->NEXTKEY;
}
sub NEXTKEY {
	my ($self,$lkey) = @_;
	my $next;
	SEEK: {
		$next = each %{$self->{keys}};
		return unless defined $next;
		redo SEEK unless exists $self->{hash}{$next};
	}
	return $next;
}

=item C<delete>ing

If the key is in the subset, the key will be deleted from the
underlying hash, but not the subset. Otherwise, the operation is
ignored and a warning issued.

=cut

sub DELETE {
	my ($self,$key) = @_;
	if (exists $self->{keys}{$key}) {
		return delete $self->{hash}{$key};
	} # else
	warnings::warnif("deleting unknown key '$key' not (yet) supported in ".ref($self).", ignoring");
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
	return scalar %{$self->{keys}};
}

sub UNTIE {
	my ($self) = @_;
	$self->{hash} = undef;
	$self->{keys} = undef;
	return;
}

1;
__END__

=back

=head1 See Also

L<Tie::Subset/"See Also">

=head1 Author, Copyright, and License

Copyright (c) 2018 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut
