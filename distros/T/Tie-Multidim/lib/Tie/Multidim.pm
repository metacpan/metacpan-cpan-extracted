
package Tie::Multidim;

use strict;
use vars qw( $VERSION );

$VERSION = '0.04';


=head1 NAME

Tie::Multidim - "tie"-like multidimensional data structures

=head1 SYNOPSIS

 use Tie::Multidim;
 my $foo = new Tie::Multidim \%h, '%@%';
 $foo->[2]{'die'}[4] = "isa";

=head1 DESCRIPTION

This module implements multi-dimensional data structures on a hash.
C<$foo-E<gt>[2]{'die'}[4]> gets "mapped" to C<$bar{"2;die;4"}>, where
the ';' is actually $SUBSEP ($;), and %bar is a hash you provide.

It is particularly useful in two, not disjoint, situations:

=over 1

=item 1.
the data space (matrix, if you prefer) is sparsely populated;

=item 2.
the hash into which the data is mapped is tied.

=back

This illustrates (1):

 my %matrix; # hash to store the data in.
 local $; = ' ';
 my $foo = new Tie::Multidim \%matrix, '@@'; # array-of-arrays.

 print $foo->[5432][9876];
 # prints the value of  $matrix{"5432 9876"}.


This illustrates (2):

 my %matrix;
 tie %matrix, 'Matrix';  # some hashtie-able class.
 local $; = ";"; # gets remembered by the object.
 my $foo = new Tie::Multidim \%matrix, '%@%';
 # 3-level structure: hash of arrays of hashes.

 $foo->{'human'}[666]{'beast'} = "value";

 # causes a call to
 sub Matrix::STORE {
   my( $self, $index, $value ) = @_;
   my( $x, $y, $z ) = split $;, $index;
   # with $x = 'human', $y = 666, and $z = 'beast'.
 }


=head1 METHODS

=head2 new

This is the constructor.

The first argument is a hash-reference.  This hash will be used by the
Tie::Multidim object to actually store the data.
The reference can be to an anonymous hash, to a normal hash, or to a
tied hash.  Tie::Multidim doesn't care, as long as it supports the 
normal hash get and set operations (STORE and FETCH methods, in TIEHASH
terminology).

The second argument is a string containing '@' and '%' characters
(a al function prototypes).  The multidimensional data structure will
be constructed to have as many dimensions as there are characters in
this string; and each dimension will be of the type indicated by the
character.  '@%' is an array of hashes; '%@' is a hash of arrays; and
so on.

=cut

	sub new {
		my( $pkg, $storage, $level_types, @index ) = @_;
#		print "new( @_ )\n";
		$level_types =~ s/[^@%]//;
		length $level_types or
			die "Level types string contains no level types!";

		my $level_type = substr $level_types, scalar @index, 1;

		my $tied = bless {
			'storage' => $storage,
			'level_types' => $level_types,
			'index' => [ @index ], # copy
			'sep' => $;,
		}, $pkg;

		if ( $level_type eq '@' ) {
			my @a;
			tie @a, $pkg, $tied;
			return \@a;
		}
		elsif ( $level_type eq '%' ) {
			my %h;
			tie %h, $pkg, $tied;
			return \%h;
		}
		else { die "Illegal level type? '$level_types'\n" }
	}

	sub FETCHSIZE {
		my( $self ) = @_;
		0
	}

	sub FETCH {
		my( $self, $index ) = @_;
		local $; = $self->{'sep'};

		@{ $self->{'index'} } < length( $self->{'level_types'} )-1 and
			return new Tie::Multidim
				$self->{'storage'},
				$self->{'level_types'},
				@{ $self->{'index'} }, $index;

		# do the real, final index:
		$self->{'storage'}{ join $;, @{ $self->{'index'} }, $index }
	}

	sub STORE {
		my( $self, $index, $value ) = @_;
		local $; = $self->{'sep'};

		# ignore attempts to set members of internal hash/array members:
		@{ $self->{'index'} } > 0 or return();

		@{ $self->{'index'} } == length( $self->{'level_types'} )-1 or die "YOW!";

		# do the real, final index:
		$self->{'storage'}{ join $;, @{ $self->{'index'} }, $index } = $value;
	}


=head2 storage

This returns the same hash reference that was passed as the first
argument to the constructor.
Not exactly a method, it must be called as a package function,
and passed the multidim reference.

	$foo = new Tie::Multidim, \%h, '@@';
	$hashref = Tie::Multidim::storage( $foo );
	# same effect as:
	$hashref = \%h;

=cut

	sub storage {
		my $tied_ref = shift;
		$tied_ref =~ /\bARRAY\b/ and return( tied( @$tied_ref )->{'storage'} );
		$tied_ref =~ /\bHASH\b/ and return( tied( %$tied_ref )->{'storage'} );
		die "'$tied_ref': not an array or hash ref!";
	}


	sub TIEARRAY { shift; shift; }

	sub TIEHASH { shift; shift; }


=head1 AUTHOR

jdporter@min.net (John Porter)

=head1 COPYRIGHT

This module is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

=cut


1;


