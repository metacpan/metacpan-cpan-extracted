#!/usr/bin/perl -w

package Tie::Array::Iterable;

#=============================================================================
#
# $Id: Iterable.pm,v 0.03 2001/11/16 02:27:56 mneylon Exp $
# $Revision: 0.03 $
# $Author: mneylon $
# $Date: 2001/11/16 02:27:56 $
# $Log: Iterable.pm,v $
# Revision 0.03  2001/11/16 02:27:56  mneylon
# Fixed packing version variables
#
# Revision 0.01.01.2  2001/11/16 02:12:14  mneylon
# Added code to clean up iterators after use
# clear_iterators() now not needed, simply returns 1;
#
# Revision 0.01.01.1  2001/11/15 01:41:19  mneylon
# Branch from 0.01 for new features
#
# Revision 0.01  2001/11/11 18:36:10  mneylon
# Initial Release
#
#
#=============================================================================

use 5.006;
use strict;
use Tie::Array;

use Tie::Array::Iterable::ForwardIterator;
use Tie::Array::Iterable::BackwardIterator;

BEGIN {
    use Exporter   ();
    use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    ( $VERSION ) = '$Revision: 0.03 $ ' =~ /\$Revision:\s+([^\s]+)/;
    @ISA         = qw( Exporter Tie::StdArray );
    @EXPORT      = qw( );
	@EXPORT_OK   = qw( iterate_from_start iterate_from_end );
    %EXPORT_TAGS = ( quick=>[ qw( iterate_from_start iterate_from_end ) ] );
}

sub new {
	my $class = shift;
	my @self;
	tie @self, $class, \@_;
	return bless \@self, $class;
}

sub TIEARRAY {
	my $class = shift;
	my $arrayref = shift || [];
	my %data = (
		array => $arrayref,
		forward_iters => [],
		backward_iters => [] );
	return bless \%data, $class;
}

sub FETCH {
	my $self = shift;
	my $index = shift;
	return $self->{ array }->[ $index ];
}

sub STORE {
	my $self = shift;
	my $index = shift;
	my $value = shift;
	$self->{ array }->[ $index ] = $value;
}

sub FETCHSIZE {
	my $self = shift;
	return scalar @{ $self->{ array } };
}

sub STORESIZE {
	my $self  = shift;
	my $count = shift;
	if ( $count > $self->FETCHSIZE() ) {
		foreach ( $count - $self->FETCHSIZE() .. $count ) {
			$self->STORE( $_, '' );
		}
	} elsif ( $count < $self->FETCHSIZE() ) {
		foreach ( 0 .. $self->FETCHSIZE() - $count - 2 ) {
			$self->POP();
		}
	}
}

sub EXTEND {
	my $self = shift;
	my $count = shift;
	$self->STORESIZE( $count );
}

sub EXISTS {
	my $self = shift;
	my $index = shift;
	return exists $self->{ array }->[ $index ];
}

sub CLEAR {
	my $self = shift;
	$self->{ array } = [];
	foreach my $iter ( $self->_get_forward_iters() ) {
		$iter->set_index( 0 );
	}
	foreach my $iter ( $self->_get_backward_iters() ) {
		$iter->set_index( 0 );
	}
	return 1;
}

sub PUSH {
	my $self = shift;
	my @list = @_;
	my $last = $self->FETCHSIZE();
	$self->STORE( $last + $_, $list[$_] ) foreach 0 .. $#list;
	foreach my $iter ( $self->_get_forward_iters() ) {
		if ( $iter->index() == $last ) {
			$iter->set_index( $last + scalar @list );
		}
	}
	foreach my $iter ( $self->_get_backward_iters() ) {
		if ( $iter->index() == $last ) {
			$iter->set_index( $last + scalar @list );
		}
	}
	return $self->FETCHSIZE();
}

sub POP {
	my $self = shift;
	foreach my $iter ( $self->_get_forward_iters() ) {
		if ( $iter->index() >= $self->FETCHSIZE() ) {
			$iter->set_index( $iter->index()-1 );
		}
	}
	foreach my $iter ( $self->_get_backward_iters() ) {
		if ( $iter->index() >= $self->FETCHSIZE() ) {
			$iter->set_index( $iter->index()-1 );
		}
	}

	return pop @{ $self->{ array } };
}

sub UNSHIFT {
	my $self = shift;
	my @list = @_;
	my $size = scalar( @list );
	# make room for our list
	@{$self->{ array }}[ $size .. $#{$self->{ array }} + $size ]
		= @{$self->{ array }};
	$self->STORE( $_, $list[$_] ) foreach 0 .. $#list;
	foreach my $iter ( $self->_get_forward_iters() ) {
		if ( $iter->index() > 0 ) {
			$iter->set_index( $iter->index() + scalar @list );
		}
	}	
	foreach my $iter ( $self->_get_backward_iters() ) {
		if ( $iter->index() > 0 ) {
			$iter->set_index( $iter->index() + scalar @list );
		}
	}	

}

sub SHIFT {
	my $self = shift;
	foreach my $iter ( $self->_get_forward_iters() ) {
		if ( $iter->index() > 0 ) {
			$iter->set_index( $iter->index()-1 );
		}
	}
	foreach my $iter ( $self->_get_backward_iters() ) {
		if ( $iter->index() > 0 ) {
			$iter->set_index( $iter->index()-1 );
		}
	}
	return shift @{ $self->{ array } };
}

sub SPLICE {
	my $self   = shift;
	my $offset = shift || 0;
	if ( $offset < 0 ) { 
		$offset = $self->FETCHSIZE() + $offset + 1;
	}
	my $length = shift;
	if ( $length == 0 && $length ne "0" ) {
		$length = $self->FETCHSIZE() - $offset;
	}
	my @list   = @_;

	# Do the splice first:
	my @data = splice @{ $self->{ array } }, $offset, $length, @list;

	foreach my $iter ( $self->_get_forward_iters() ) {
		# If beyond the splice point...
		if ( $iter->index() > $offset ) {
			# If outside of the offset boundary
			if ( $iter->index() > $offset + $length ) {
				# Simply adjust the counter
				$iter->set_index( $iter->index() + 
					( scalar @list - $length ) );
			} else {
				# Push the iter back to the offset point
				$iter->set_index( $offset );
			}
		}	
	}
	foreach my $iter ( $self->_get_backward_iters() ) {
		# If beyond the splice point...
		if ( $iter->index() > $offset ) {
			# If outside of the offset boundary
			if ( $iter->index() > $offset + $length ) {
				# Simply adjust the counter
				$iter->set_index( $iter->index() + 
					( scalar @list - $length ) );
			} else {
				# Push the iter back to the offset point
				$iter->set_index( $offset + scalar @list + 1 );
			}
		}	
	}
	return splice @data;
}

sub from_start () {
	my $self = shift;
	my $iter = new Tie::Array::Iterable::ForwardIterator( $self, 0 );
	push @{ tied(@$self)->{ forward_iters } }, $iter->_id();
	return $iter;
}

sub forward_from  {
	my $self = shift;
	my $pos = shift;
	if ( $pos == 0 && $pos ne "0" ) {
		$pos = 0;
	}
	die "Position must be in array bounds"
		unless $pos >= 0 && $pos < scalar @$self;
	my $iter = new Tie::Array::Iterable::ForwardIterator( $self, $pos );
	push @{ tied(@$self)->{ forward_iters } }, $iter->_id();
	return $iter;
}

sub from_end () {
	my $self = shift;
	my $iter = new Tie::Array::Iterable::BackwardIterator( $self, 
		scalar @$self );
	push @{ tied(@$self)->{ backward_iters } }, $iter->_id();
	return $iter;
}

sub backward_from {
	my $self = shift;
	my $pos = shift;
	if ( $pos == 0 && $pos ne "0" ) {
		$pos = scalar @$self;
	}
	die "Position must be in array bounds"
		unless $pos >= 0 && $pos <= scalar @$self;
	my $iter = new Tie::Array::Iterable::BackwardIterator( $self, $pos );
	push @{ tied(@$self)->{ backward_iters } }, $iter->_id();
	return $iter;
}

# This function is no longer necessary

sub clear_iterators {
	1;
}


sub iterate_from_start {
	my $array = new Tie::Array::Iterable( @_ );
	return $array->from_start();
}

sub iterate_from_end {
	my $array = new Tie::Array::Iterable( @_ );
	return $array->from_end();
}

sub iterate_forward_from {
    my $pos = shift;
	my $array = new Tie::Array::Iterable( @_ );
	return $array->forward_from( $pos );
}

sub iterate_backward_from {
    my $pos = shift;
	my $array = new Tie::Array::Iterable( @_ );
	return $array->backward_from( $pos );
}

sub _get_forward_iters {
	my $self = shift;
	return grep { $_ } 
	       map { Tie::Array::Iterable::ForwardIterator::_lookup( $_ ) }
		   @{ $self->{ forward_iters } };
}

sub _get_backward_iters {
	my $self = shift;
	return grep { $_ } 
	       map { Tie::Array::Iterable::BackwardIterator::_lookup( $_ ) }
		   @{ $self->{ backward_iters } };
}

sub _remove_forward_iterator {
	my $self = shift;
	my $id = shift;
	use Data::Dumper;
	tied(@$self)->{ forward_iters } = [
		grep { $_ != $id }
		@{ tied(@$self)->{ forward_iters } } ];
}

sub _remove_backward_iterator {
	my $self = shift;
	my $id = shift;
	tied(@$self)->{ backward_iters } = [
		grep { $_ != $id }
		@{ tied(@$self)->{ backward_iters } } ];
}

1;
__END__

=head1 NAME

Tie::Array::Iterable - Allows creation of iterators for lists and arrays

=head1 SYNOPSIS

  use Tie::Array::Iterable qw( quick );
  
  my $iterarray = new Tie::Array::Iterable( 1..10 );
  for( my $iter = $iterarray->start() ; !$iter->at_end() ; $iter->next() ) {
	print $iter->index(), " : ", $iter->value();
	if ( $iter->value() == 3 ) {
		unshift @$iterarray, (11..15); 
	}
  }

  my @array = ( 1..10 );
  for( my $iter = iterator_from_start( @array ) ; 
	   !$iter->at_end() ;
	   $iter->next() ) { ... }

  for( my $iter = iterate_from_end( @array ) ;
       !$iter->at_end() ;
	   $iter->next() ) { ... } 

=head1 DESCRIPTION

C<Tie::Hash::Iterable> allows one to create iterators for lists and arrays.
The concept of iterators is borrowed from the C++ STL [1], in which most of 
the collections have iterators, though this class does not attempt to fully 
mimic it.  

Typically, in C/C++ or Perl, the 'easy' way to visit each item on a list is 
to use a counter, and then a for( ;; ) loop.  However, this requires
knowledge on how long the array is to know when to end.  In addition, if 
items are removed or inserted into the array during the loop, then the 
counter will be incorrect on the next run through the loop, and will cause
problems.

While some aspects of this are fixed in Perl by the use of for or foreach,
these commands still suffer when items are removed or added to the array
while in these loops.  Also, if one wished to use break to step out of a
foreach loop, then restart where they left at some later point, there is
no way to do this without maintaining some additional state information.

The concept of iterators is that each iterator is a bookmark to a spot, 
typically concidered between two elements.  While there is some overhead
to the use of iterators, it allows elements to be added or removed from 
the list, with the iterator adjusting appropriate, and allows the state
of a list traversal to be saved when needed.  

For example, the following perl code will drop into an endless block 
(this mimics the functionality of the above code):

   my @array = (0..10);
   for my $i ( @a ) {
       print "$i\n";
	   if ( $i == 3 ) { unshift @a, ( 11..15 ); } 
   }

However, the synopsis code will not be impared when the unshift operation
is performed; the iteration will simply continue at the next element, 
being 4 in this case.

Tie::Array::Iterable does this by first tying the desired list to this 
class as well as blessing it in order to give it functionality.  When 
a new iterator is requested via the iterable array object, a new object
is generated from either Tie::Array::Iterable::ForwardIterator or
Tie::Array::Iterable::BackwardIterator.  These objects are then used in
associated for loops to move through the array and to access values.
When changes in the positions of elements of the initial array are made, 
the tied variable does the appropriate bookkeeping with any iterators 
that have been created to make sure they point to the appropriate elements.

Note that the iterable array object is also a tied array, and thus, you 
can use all standard array operations on it (with arrow notation due to
the reference, of course).

The logic behind how iterators will 'move' depending on actions are 
listed here.  Given the list

    0 1 2 3 4 5 6 7 8 9 10
             ^
             Forward iterator current position

Several possible cases can be considered:

=over

=item unshift

If an item was unshifted on the list, thus pushing all elements to the
right, the iterator will follow this and will still point to 5.

=item shift

Removing an item from the start of the list will push all elements to the
left, and the iterator again will follow and point to 5.

=item pop, push

Since these affect the list after the position of the iterator, there is
no change in the iterator at this time.  However, an iterator that is
at the end of the list will pass over these new elements if it is moved
backwards though the list.

=item splice 3, 4, () 

If the array is spliced from 3 to 6, then the position that the iterator is
at is invalid, and is pushed back to the last 'valid' entry, this being
between 2 and 7 after the splice and pointing to 7.

=item splice 3, 4, ( 11, 12, 13 )

Even though we are adding new data, this is similar to the situation 
above, and the iterator will end up pointing at 11, sitting between 2
and 11.

=item splice 4, 0, ( 11, 12, 13 )

This will push extra data between 3 and 4, but does not affect the 
position of the iteration, which will still point at 5.

=item splice 5, 0, ( 11, 12, 13 )

Because the data is now being pushed between 4 and 5, this will affect
the iterator, and the iterator will now point at 11.

=item splice 0, 6

Remove all data from the head to the iterator position will result it 
in being at the leftmost part of the array, and will be pointing at 7.

=back

This is only for the forward iterator; the backwards iterator would
work similarly.

=head2 PACKAGE METHODS

=over

=item new( [<array>] )

Creates a new iterable array object; this is returned as a reference
to an array.  If an array is passed, then the iterable array is set up
to use this array as storage.

=item iterate_from_start( <list> )

Returns a forward iterator that can be used to iterator over the given 
list.  This allows one to avoid explicitly creating the iterable array
object first, though one still is created for this purpose.

=item iterate_from_end( <list> )

Returns a backwards iterator that can be used to iterate over the
given list.

=item iterate_forward_from( <int>, <list> )

Returns a forward iterator for the given list set at the indicated
position.

=item iterate_backward_from( <int>, <list> ) 

Returns a backward iterator for the given list set at the indicated
position.

=back

=head2 CLASS METHODS

=over

=item from_start( )

Returns a new forward iterator set at the start of the array.
Parentheses are not required.

=item from_end( )

Returns a new backward iterator set at the end of the array.
Parentheses are not required.

=item forward_from ([<int>]) 

Returns a new forward iterator set at the indicated position (or at 
the start of the array if no value is passed).

=item backward_from ([<int>])

Returns a new backward iterator set at the indicated position (or at
the end of the array if no value is passed).

=item clear_iterators( )

This function was previously used to clear references that might
accumulate; however, this functionality has been fixed, and this
function does nothing besides return a true value.

=back

=head2 ITERATOR METHODS

The iterators that are generated by the functions above have the 
following functions associated with them.

=over

=item value()

Returns the current value from the array where the iterator is pointing,
or undef if the iterator is at the end.

=item set_value( <value> ) 

Sets the value of the array where the iterator is currently positions to 
the passed value.  This will do nothing if the iterator is at the end 
of the array.

=item index()

Returns the index in the array where the iterator is currently pointing.

=item set_index( <pos> )

Moves the iterator to this position in the array.

=item at_end()

Returns true if the iterator is pointing at the end position (at the end
of the array for a Forward iterator, at the start of the array for the
Backward iterator), false otherwise.  Parentheses are not required.

=item at_start()

Returns true if the iterator is pointing at the start position (at the
beginning of the array for a Forward iterator, at the end of the array 
for the Backward iterator), false otherwise.  Parentheses are not required.

=item next()

Advances the iterator to the next position; the value of this new 
position is returned as per C<value()>.  This will not move past the
end position.  Parentheses are not required.


=item prev()

Advances the iterator to the previous position; the value of this
new position is returned as per C<value()>.  This will not move past
the starting position.  Parentheses are not required.

=item to_end()

Advances the iterator to the very end position.  Note that this is the
undefined state, and the only way to resume traversal is to move to
preceeding elements.  Also note that for a backwards iterator, this
means to move to the beginning of the array.  Parentheses are not required.


=item to_start()

Advances the iterator back to the starting position for the iterator.
Again, for a backwards iterator, this means moving to the end of the 
list.  Parentheses are not required.

=item forward( [<int>] )

Advances the iterator in the forward direction the number of steps 
passed, or just 1 if no value is passed (and thus acting like C<next()>).

=item backward( [<int>] )

Advances the iterator in the backward direction the number of steps
passed, or just 1 if no value is passed (and thus acting like C<prev()>).

=back

=head1 EXPORT

The 'quick' export will export C<iterate_from_start>, C<iterate_from_end>,
C<iterate_forward_from>, and C<iterate_backward_from> functions into 
the global namespace.  Optionally, you may import these functions
individually.

=head1 CAVAETS

You should not directly tie your array to this class, nor use the 
ForwardIterator or BackwardIterator classes directly.  There are
factory-like methods for these classes that you should use instead.

You might run in to trouble if you use more than MAXINT (typically 2^32 on
most 32-bit machines) iterators during a single instance of the program.  
If this is a practical concern, please let me know; that can be fixed
though with some time consumption.

=head1 AUTHOR

Michael K. Neylon E<lt>mneylon-pm@masemware.comE<gt>

=head1 ACKNOWLEDGEMENTS

I'd like to thank Chip Salzenberg for a useful suggesting in helping to
remove the reference problem without having to resort to weak references
on Perlmonks.

=head1 REFERENCES

[1] A reference guide to the C++ STL can be found at 
    http://www.cs.rpi.edu/projects/STL/htdocs/stl.html

=head1 COPYRIGHT

Copyright 2001 by Michael K. Neylon E<lt>mneylon-pm@masemware.comE<gt>.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
