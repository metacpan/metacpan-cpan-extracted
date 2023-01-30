#!perl
package Tie::Subset::Array;
use warnings;
use strict;
use warnings::register;
use Carp;

# For AUTHOR, COPYRIGHT, AND LICENSE see the bottom of this file

=head1 Name

Tie::Subset::Array - Tie an array to a subset of another array

=head1 Synopsis

 use Tie::Subset::Array;
 my @array = (55,66,77,88,99);
 tie my @subset, 'Tie::Subset::Array', \@array, [1,2,3];
 print "$subset[1]\n";  # prints "77"
 $subset[2]++;          # modifies $array[3]

=head1 Description

This class for tied arrays provides a "view" of a subset of an array.

=over

=cut

our $VERSION = '0.02';

=item C<tie>ing

 tie my @subset, 'Tie::Subset::Array', \@array, \@indices;

You must specify which subset of indices from the original array
should be part of the new array. (Indices that do not yet exist in
the original array may be specified.) The subset (tied array) will
be the same size as C<@indices>, and is indexed by the usual 0 to
C<$#subset>.

=cut

sub TIEARRAY {  ## no critic (RequireArgUnpacking)
	@_==3 or croak "bad number of arguments to tie";
	my ($class, $arr, $idx) = @_;
	ref $arr eq 'ARRAY' or croak "must provide arrayref to tie";
	ref $idx eq 'ARRAY' or croak "must provide index list to tie";
	for (@$idx) { croak "bad array index '$_'" if ref || !/\A[0-9]+\z/ }
	my $self = { arr => $arr, idx => [@$idx] };
	return bless $self, $class;
}

sub FETCHSIZE {
	my ($self) = @_;
	return scalar @{ $self->{idx} };
}

=item Fetching

If the index is within the bounds of the tied array, the value from
the underlying array is returned, otherwise returns nothing (undef).

=cut

sub FETCH {
	my ($self,$i) = @_;
	# uncoverable branch true
	return if $i < 0;
	return if $i > $#{ $self->{idx} };
	return $self->{arr}[ $self->{idx}[$i] ];
}

=item Storing

If the index is within the bounds of the tied array, the new value
will be stored in the underlying array, otherwise the operation is
ignored and a warning issued.

=cut

sub STORE {
	my ($self,$i,$v) = @_;
	return if $i < 0; # uncoverable branch true
	if ( $i > $#{ $self->{idx} } ) {
		warnings::warnif("storing values outside of the subset not (yet) supported in ".ref($self));
		return;
	}
	return $self->{arr}[ $self->{idx}[$i] ] = $v;
}

=item C<exists>

B<Note:> The Perl documentation strongly discourages from calling 
L<exists|perlfunc/exists> on array values.

Will return true only if the index C<exists> in the subset I<and>
the corresponding index in the underlying array C<exists>.

=cut

sub EXISTS {
	my ($self,$i) = @_;
	return exists $self->{idx}[$i] && exists $self->{arr}[ $self->{idx}[$i] ];
}

sub UNTIE {
	my ($self) = @_;
	$self->{arr} = undef;
	$self->{idx} = undef;
	return;
}

=item I<Not Supported>

Any operations that modify the size of the tied array are not (yet)
supported (because it is ambiguous how such operations should
affect the underlying array). Attempting to change the tied array's
size, including using C<push>, C<pop>, C<shift>, C<unshift>,
C<splice>, assigning to the C<$#array> notation, clearing the
array, etc. will currently do nothing and cause a warning to be
issued, and operations that normally return a value will return
nothing.

The above is also true for attempting to C<delete> array elements,
which the Perl documentation strongly discourages anyway.

A future version of this module may lift these limitations (if a
useful default behavior exists).

=cut

sub STORESIZE {
	my ($self,$s) = @_;
	warnings::warnif("extending or shrinking of ".ref($self)." not (yet) supported");
	return;
}

sub CLEAR {
	my ($self) = @_;
	warnings::warnif("clearing of ".ref($self)." not (yet) supported");
	return;
}

sub PUSH {
	my ($self,@list) = @_;
	warnings::warnif("pushing onto ".ref($self)." not (yet) supported");
	return;
}

sub POP {
	my ($self) = @_;
	warnings::warnif("popping from ".ref($self)." not (yet) supported");
	return;
}

sub SHIFT {
	my ($self) = @_;
	warnings::warnif("shifting from ".ref($self)." not (yet) supported");
	return;
}

sub UNSHIFT {
	my ($self,@list) = @_;
	warnings::warnif("unshifting onto ".ref($self)." not (yet) supported");
	return;
}

sub SPLICE {
	my ($self,$off,$len,@list) = @_;
	warnings::warnif("splicing ".ref($self)." not (yet) supported");
	return;
}

sub EXTEND {
	# uncoverable subroutine
	my ($self,$s) = @_;  # uncoverable statement
	warnings::warnif("extending ".ref($self)." not (yet) supported");  # uncoverable statement
	return;  # uncoverable statement
}

sub DELETE {
	my ($self,$i) = @_;
	warnings::warnif("deleting from ".ref($self)." not (yet) supported");
	return;
}

1;
__END__

=back

=head1 See Also

L<Tie::Subset/"See Also">

=head1 Author, Copyright, and License

Copyright (c) 2018-2023 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut
