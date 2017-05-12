
package Tie::OffsetArray;

use vars qw( $VERSION @ISA );

$VERSION = '0.01';

require 5.005;
use Tie::Array;
@ISA = qw( Tie::Array );

use strict;



	sub TIEARRAY {
		my( $pkg, $offset, $ar ) = @_;
		$offset >= 0 or die "Offset must be non-negative!";
		defined($ar) or $ar = [];
		$ar =~ /\bARRAY\b/ or die "Illegal argument: $ar\n";
		while ( @$ar < $offset ) { push @$ar, undef }
		bless [ $offset, $ar ], $pkg
	}

	sub FETCH {
		my( $self, $index ) = @_;
		$self->[1][ $index + $self->[0] ]
	}

	sub STORE {
		my( $self, $index, $value ) = @_;
		$self->[1][ $index + $self->[0] ] = $value;
	}

	sub FETCHSIZE {
		my( $self ) = @_;
		@{ $self->[1] } - $self->[0]
	}

	sub STORESIZE {
		my( $self, $size ) = @_;
		$#{ $self->[1] } = $size + $self->[0] - 1 + $[;
	}

	# get (a ref to) the underlying array 
	sub array {
		my( $self ) = @_;
		$self->[1]
	}

1;

__END__

=head1 NAME

Tie::OffsetArray - Tie one array to another, with index offset

=head1 SYNOPSIS

  use Tie::OffsetArray;

  tie @a, 'Tie::OffsetArray', 1, \@b; # offset=1; use given array.

  tie @c, 'Tie::OffsetArray', 2;      # use anonymous array.

  $a[0] = 'x';                        # assign to $b[1];

  tied(@a)->array->[0] = 'y';         # assign to $b[0].

=head1 DESCRIPTION

When tied to this class, an array's behavior is completely
normal.  For its internal storage, it uses another array,
either one supplied by the caller, or a new anonymous one.
Accesses to the tied array are mapped down to the storage
array by offsetting the index by some constant amount. 

A special method on the tied object returns a reference to
the storage array, so that the elements below the offset
can be accessed.  This is particularly useful if the storage
array was not supplied by the caller.

=head1 AUTHOR

jdporter@min.net (John Porter)

=head1 COPYRIGHT

This is free software.  This software may be modified and
distributed under the same terms as Perl itself.

=cut

