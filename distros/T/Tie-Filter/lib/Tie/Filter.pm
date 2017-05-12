package Tie::Filter;

use 5.008;
use strict;
use warnings;

our $VERSION = '1.02';

=head1 NAME

Tie::Filter - Tie a facade around a scalar, array, or hash

=head1 SYNOPSIS

  use Tie::Filter;

  # SCALARS
  my $wrapped;
  tie $scalar, 'Tie::Filter', \$wrapped,
      FETCH => sub { $_ = lc },
      STORE => sub { $_ = uc };

  # ARRAYS
  my @wrapped;
  tie @array, 'Tie::Filter', \@wrapped,
      FETCH => sub { $_ = uc },
      STORE => sub { $_ = lc };

  # HASHES
  my %wrapped;
  tie %hash, 'Tie::Filter', \%wrapped,
      FETCHKEY   => sub { $_ = lc },
      STOREKEY   => sub { $_ = uc },
      FETCHVALUE => sub { $_ = uc },
      STOREVALUE => sub { $_ = lc };

=head1 DESCRIPTION

This module ties a facade around a scalar, array, or hash. The facade then
filters data as it is being fetched from or stored to the internal object.
For scalars, it provides an API for filtering values stored to and fetched
from an internal scalar. For arrays, it provides an API for filtering
elements stored in an internal array. For hashes, it provides an API for
filtering the keys and values stored in the internal hash.

This is meant to provide an easy form of syntactic sugar to be built upon
other objects. The original purpose of this library was to provide a drop in
replacement for DBM filters for general hashes. It is capable of much more.

=head2 WRITING FETCH AND STORE

The only work that needs to be done is to provide the methods for fetching and
storing keys and values. Fetching occurs when taking internal data and using it
externally and storing occurs when taking external data and using it internally.
(These terms are not directly related to the C<FETCH> and C<STORE> methods of a
tied object.)

Each fetch and store method will have the filtered variable set in C<$_>. The
method should then modify this variable in place to perform filtering. The
return value of the method is ignored.

=head1 CAVEATS

Be careful that your FETCH/STORE methods will properly handle all possible
inputs; be especially careful of C<undef>. For example, this might seem safe:

  # THIS CAUSES AN ERROR
  use strict;
  tie %hash, 'Tie::Filter', %wrapped,
      STOREVALUE => sub { $_ = join ':', @{ $_ } },
	  FETCHVALUE => sub { $_ = [ split /:/, $_ ] };
  $hash{foo} = undef; # Can't use an undefined value as an ARRAY reference

This is also dangerous when using C<undef> as elements of an array which will
be lost or changed to an empty string upon retrieval depending on the contents
of the rest of the array.

=cut

sub TIESCALAR {
	my $class = shift;
	require Tie::Filter::Scalar;
	return Tie::Filter::Scalar->TIESCALAR(@_);
}

sub TIEARRAY {
	my $class = shift;
	require Tie::Filter::Array;
	return Tie::Filter::Array->TIEARRAY(@_);
}

sub TIEHASH {
	my $class = shift;
	require Tie::Filter::Hash;
	return Tie::Filter::Hash->TIEHASH(@_);
}

sub _filter {
	my $code = shift;
	if (defined $code) {
		local $_ = shift;
		&$code;
		return $_;
	} else {
		return shift;
	}
}

=head1 SEE ALSO

L<perltie>, L<Tie::Filter>

=head1 TO DO

I would like to add support for creating filters around file handles with a
similar interface, but this is a much more complicated problem then the creation
of a facade around scalars, arrays, and hashes.

Anyone who is interested is welcome to contribute a C<Tie::Filter::Handle>
package for consideration. Send any ideas or comments to my email address below.

=head1 AUTHOR

  Andrew Sterling Hanenkamp, <sterling@hanenkamp.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2003 Andrew Sterling Hanenkamp. All Rights Reserved. This library is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut


