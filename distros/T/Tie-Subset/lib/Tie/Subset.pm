#!perl
package Tie::Subset;
use warnings;
use strict;
use Carp;

# For AUTHOR, COPYRIGHT, AND LICENSE see the bottom of this file

=head1 Name

Tie::Subset - Tie an array or hash to a subset of another array or hash, respectively

=head1 Synopsis

 use Tie::Subset;
 
 my %hash = ( foo=>11, bar=>22, quz=>33 );
 tie my %subset, 'Tie::Subset', \%hash, ['bar','quz'];
 # same as tie-ing to 'Tie::Subset::Hash'
 
 my @array = (55,66,77,88,99);
 tie my @subset, 'Tie::Subset', \@array, [1,2,3];
 # same as tie-ing to 'Tie::Subset::Array'

=head1 Description

This class simply delegates to
B<L<Tie::Subset::Hash|Tie::Subset::Hash>> or
B<L<Tie::Subset::Array|Tie::Subset::Array>> as appropriate.
Please see the documentation of those modules.

=cut

our $VERSION = '0.01';

sub TIEHASH {  ## no critic (RequireArgUnpacking)
	require Tie::Subset::Hash;
	@_>1 or croak "bad number of arguments to tie";
	my $class = shift;
	$class = 'Tie::Subset::Hash' if $class eq __PACKAGE__;
	return Tie::Subset::Hash::TIEHASH($class, @_);
}

sub TIEARRAY {  ## no critic (RequireArgUnpacking)
	require Tie::Subset::Array;
	@_>1 or croak "bad number of arguments to tie";
	my $class = shift;
	$class = 'Tie::Subset::Array' if $class eq __PACKAGE__;
	return Tie::Subset::Array::TIEARRAY($class, @_);
}

1;
__END__

=head1 See Also

=over

=item *

L<Data::Alias>

=item *

L<perlref/"Assigning to References">

=item *

Tie::StdScalar from L<Tie::Scalar>

=back

=head2 Note

The module L<Tie::Subset::Array|Tie::Subset::Array> is primarily
provided for orthogonality with
L<Tie::Subset::Hash|Tie::Subset::Hash>. The following "trick" can
be used to get an array reference where the elements are
I<aliases> to the original array:

 my $subset = sub { \@_ }->( @array[@indices] );

However, note there are differences between the behavior of this
code and L<Tie::Subset::Array|Tie::Subset::Array> with respect to
array indices that lie outside of the range of either array. For
details, please see the file F<t/80_alias.t> that is part of this
module's distribution.

=head1 Author, Copyright, and License

Copyright (c) 2018 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut
