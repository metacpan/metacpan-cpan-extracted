package Ruby::Collections::Array;
use Tie::Array;
our @ISA = 'Tie::StdArray';
use strict;
use v5.10;
use Scalar::Util qw(looks_like_number reftype);
use Math::Combinatorics;
use Set::CrossProduct;
use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Ruby::Collections;
use overload (
	'+'  => \&add,
	'-'  => \&minus,
	'*'  => \&multiply,
	'&'  => \&intersection,
	'|'  => \&union,
	'<<' => \&double_left_arrows,
	'==' => \&eql,
	'eq' => \&eql,
	'!=' => \&not_eql,
	'ne' => \&not_eql,
	'""' => \&to_s
);

=item add()
  Append other ARRAY to itself.
=cut

sub add {
	my ( $self, $other_ary ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	@new_ary = @$self;
	push( @new_ary, @{$other_ary} );

	return $new_ary;
}

=item minus()
  Remove all elements which other ARRAY contains from itself.
=cut

sub minus {
	my ( $self, $other_ary ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	@new_ary = @{$self};
	for my $item ( @{$other_ary} ) {
		$new_ary->delete($item);
	}

	return $new_ary;
}

=item multiply()
  Duplicate self by a number of times or join all elements by a string.
=cut

sub multiply {
	my ( $self, $sep_or_n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	if ( looks_like_number $sep_or_n ) {
		die 'ArgumentError: negative argument' if ( $sep_or_n < 0 );

		for ( my $i = 0 ; $i < $sep_or_n ; $i++ ) {
			push( @new_ary, @{$self} );
		}
		return $new_ary;
	}
	else {
		return join( $sep_or_n, @{$self} );
	}
}

=item intersection()
  Generate an intersection set between self and other ARRAY.
=cut

sub intersection {
	my ( $self, $other ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	foreach my $item ( @{$self} ) {
		if (   ( not $new_ary->include($item) )
			&& $self->include($item)
			&& ra($other)->include($item) )
		{
			$new_ary->push($item);
		}
	}

	return $new_ary;
}

=item has_all()
  Check if all elements are defined.
  When block given, check if all results returned by block are true.
=cut

sub has_all {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	for my $item ( @{$self} ) {
		if ( defined $block ) {
			return 0 if ( not $block->($item) );
		}
		else {
			return 0 if ( not defined $item );
		}
	}

	return 1;
}

=item has_any()
  Check if any element is defined.
  When block given, check if any result returned by block are true.
=cut

sub has_any {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	for my $item ( @{$self} ) {
		if ( defined $block ) {
			return 1 if ( $block->($item) );
		}
		else {
			return 1 if ( defined $item );
		}
	}

	return 0;
}

=item assoc()
  Find the first sub array which contains target object as the first element.
=cut

sub assoc {
	my ( $self, $target ) = @_;
	ref($self) eq __PACKAGE__ or die;

	for my $item ( @{$self} ) {
		if ( reftype($item) eq 'ARRAY' ) {
			my @sub_array = @{$item};
			if ( p_obj( $sub_array[0] ) eq p_obj($target) ) {
				my $ret = tie my @ret, 'Ruby::Collections::Array';
				@ret = @sub_array;
				return $ret;
			}
		}
	}

	return undef;
}

=item at()
  Return the element of certain position.
  Return undef if element is not found.
=cut

sub at {
	my ( $self, $index ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return @{$self}[$index];
}

=item bsearch()
  Find the element by certain condition.
  Return undef if element is not found.
  Note: The real binary search is not implemented yet.
=cut

sub bsearch {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	for my $item ( @{$self} ) {
		if ( $block->($item) ) {
			return $item;
		}
	}

	return undef;
}

=item chunk()
  Chunk consecutive elements which is under certain condition
  into [ condition, [ elements... ] ] array.
  
  ra( 1, 3, 2, 4, 5, 6 )->chunk( sub { $_[0] % 2 } )
  # return [ [ 1, [ 1, 3 ] ], [ 0, [ 2, 4 ] ], [ 1, [5] ], [ 0, [6] ] ]
=cut

sub chunk {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	my $prev    = undef;
	my $chunk   = tie my @chunk, 'Ruby::Collections::Array';
	for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
		my $key = $block->( @{$self}[$i] );
		if ( p_obj($key) eq p_obj($prev) ) {
			$chunk->push( @{$self}[$i] );
		}
		else {
			if ( $i != 0 ) {
				my $sub_ary = tie my @sub_ary, 'Ruby::Collections::Array';
				$sub_ary->push( $prev, $chunk );
				$new_ary->push($sub_ary);
			}
			$prev = $key;
			$chunk = tie my @chunk, 'Ruby::Collections::Array';
			$chunk->push( @{$self}[$i] );
		}
	}
	if ( $chunk->has_any ) {
		my $sub_ary = tie my @sub_ary, 'Ruby::Collections::Array';
		$sub_ary->push( $prev, $chunk );
		$new_ary->push($sub_ary);
	}

	return $new_ary;
}

=item clear()
  Clear all elements.
=cut

sub clear {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	@{$self} = ();

	return $self;
}

=item combination()
  Generate all combinations of certain length n of all elements.
  
  ra( 1, 2, 3, 4 )->combination(2) # return  [[1, 2], [1, 3], [1, 4], [2, 3], [2, 4], [3, 4]] 
  ra( 1, 2, 3 )->combination( 3, sub {
  	  print $_[0]->to_s;
  } )
  # print "[3, 1, 2]"
=cut

sub combination {
	my ( $self, $n, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;
	my $combinat =
	  Math::Combinatorics->new( count => $n, data => [ @{$self} ] );

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	if ( $n < 0 ) {
		if ( defined $block ) {
			return $self;
		}
		else {
			return $new_ary;
		}
	}
	if ( $n == 0 ) {
		if ( defined $block ) {
			$block->( tie my @empty_ary, 'Ruby::Collections::Array' );
			return $self;
		}
		else {
			push( @new_ary, tie my @empty_ary, 'Ruby::Collections::Array' );
			return $new_ary;
		}
	}

	while ( my @combo = $combinat->next_combination ) {
		my $c = tie my @c, 'Ruby::Collections::Array';
		@c = @combo;
		if ( defined $block ) {
			$block->($c);
		}
		else {
			push( @new_ary, $c );
		}
	}

	if ( defined $block ) {
		return $self;
	}
	else {
		return $new_ary;
	}
}

=item compact()
  Remove all undef elements and store the result in a Ruby::Collections::Array.
  
  ra( 1, undef, 3, undef, 5 )->compact # return [ 1, 3, 5 ]
=cut

sub compact {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	for my $item ( @{$self} ) {
		if ( defined $item ) {
			push( @new_ary, $item );
		}
	}

	return $new_ary;
}

=item compactEx()
  Remove all undef elements in self.
  
  ra( 1, undef, 3, undef, 5 )->compact # return [ 1, 3, 5 ]
=cut

sub compactEx {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	my @new_ary;
	for my $item ( @{$self} ) {
		if ( defined $item ) {
			push( @new_ary, $item );
		}
	}
	@{$self} = @new_ary;

	return $self;
}

=item concat()
  Append another array to self.
  
  ra(1, 2, 3)->concat([4, 5]) # return [1, 2, 3, 4, 5]
=cut

sub concat {
	my ( $self, $other_ary ) = @_;
	ref($self) eq __PACKAGE__ or die;

	push( @{$self}, @{$other_ary} );

	return $self;
}

=item count()
  Return the amount of elements
  
  ra(1, 2, 3)->count() #return 3 
  ra(1, 2, 2)->count(2) #return 2
  ra(1, 2, 3)->count( sub { $_[0] > 0 } ) #return 3
=cut

sub count {
	my ( $self, $obj_or_block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $obj_or_block ) {
		if ( ref($obj_or_block) eq 'CODE' ) {
			my $count = 0;
			for my $item ( @{$self} ) {
				if ( $obj_or_block->($item) ) {
					$count++;
				}
			}
			return $count;
		}
		else {
			my $count = 0;
			for my $item ( @{$self} ) {
				if ( p_obj($obj_or_block) eq p_obj($item) ) {
					$count++;
				}
			}
			return $count;
		}
	}

	return scalar( @{$self} );
}

=item cycle()
  Calls the block for each element n times.
  It runs forever, if n is not given.
  
  ra(1, 2, 3)->cycle(2 , sub { print $_[0] + 1 + ", " })  # print  "2, 3, 4, 2, 3, 4, "
  
  ra(1, 2, 3)->cycle(sub { print $_[0] + 1 + ", " })  # print  "2, 3, 4, 2, 3, 4, .... forever
=cut

sub cycle {
	my ( $self, $n_or_block, $block_or_n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $n_or_block && not $block_or_n ) {
		if ( ref($n_or_block) eq 'CODE' ) {
			while (1) {
				for my $item ( @{$self} ) {
					$n_or_block->($item);
				}
			}
		}
	}
	else {
		for ( my $i = 0 ; $i < $n_or_block ; $i++ ) {
			for my $item ( @{$self} ) {
				$block_or_n->($item);
			}
		}
	}
}

=item delete()
  Delete all the items in self if equal to the given value, and return it.
  
  ra(1, 3, 5)->delete(3); #return 3
=cut

sub delete {
	my ( $self, $target, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $before_len = scalar( @{$self} );
	@{$self} = grep { p_obj($_) ne p_obj($target) } @{$self};

	if ( $before_len == scalar( @{$self} ) ) {
		if ( defined $block ) {
			return $block->();
		}
		return undef;
	}
	else {
		return $target;
	}
}

=item delete_at()
  Delete the element at the given index, and return it.
  
  ra(1, 2, 3)->delete_at(2); #return 3
=cut 

sub delete_at {
	my ( $self, $index ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $target = @{$self}[$index];

	if ( scalar( @{$self} ) == 0 ) {
		return undef;
	}
	elsif ( $index >= 0 && $index < scalar( @{$self} ) ) {
		splice( @{$self}, $index, 1 );
		return $target;
	}
	elsif ( $index <= -1 && $index >= -scalar( @{$self} ) ) {
		splice( @{$self}, $index, 1 );
		return $target;
	}
	else {
		return undef;
	}
}

=item delete_if()
  Deletes every elements of self if the block evaluates to true.
  
  ra(1, 2, 3)->delete_if ( sub { |e| e > 2}); #return ra(1, 2)
=cut

sub delete_if {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	@{$self} = grep { !$block->($_) } @{$self};

	return $self;
}

=item drop()
  Drop first n elements in array and return rest elements in a new array.
  
  ra(1, 3, 5, 7, 9)->drop(3); #return ra(7, 9)
=cut

sub drop {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( $n < 0 ) {
		die 'attempt to drop negative size';
	}

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	for my $i ( 0 .. scalar( @{$self} ) - 1 ) {
		if ( $i >= $n ) {
			push( @new_ary, @{$self}[$i] );
		}
	}

	return $new_ary;
}

=item drop_while
  Drop the elememts up to, but not including, the first element which the block returns false,
  and return the rest elements as a new array.
  
  ra(1, 2, 3, 4, 5, 1, 4)->drop_while( sub { $_[0] < 2 } ); #retrun ra( 2, 3, 4, 5, 1, 4 )
=cut

sub drop_while {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $cut_point = undef;
	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	for my $item ( @{$self} ) {
		if ( ( not $block->($item) ) || $cut_point ) {
			$cut_point = 1;
			push( @new_ary, $item );
		}
	}

	return $new_ary;
}

=item each()
  Passing each element in self as a parameter to the call block.
  Alias: each_entry()
  
  ra(1, 2, 3)->each(sub { print $_[0] }); #return ra(1, 2, 3)
=cut

sub each {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	for my $item ( @{$self} ) {
		$block->($item);
	}

	return $self;
}

=item each_cons()
  Group each element with (n-1) following members in to an new array until the last element included.
  
  ra(1, 2, 3, 4, 5, 6, 7, 8)->each_cons(5); #return ra(ra(1, 2, 3, 4, 5), ra(2, 3, 4, 5, 6), ra(3, 4, 5, 6, 7), ra(4, 5, 6, 7, 8))
=cut

sub each_cons {
	my ( $self, $n, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	die 'ArgumentError: invalid size' if ( $n <= 0 );

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
		if ( $i + $n <= scalar( @{$self} ) ) {
			my $cons = tie my @cons, 'Ruby::Collections::Array';
			for ( my $j = $i ; $j < $i + $n ; $j++ ) {
				$cons->push( $self->at($j) );
			}
			if ( defined $block ) {
				$block->($cons);
			}
			else {
				push( @new_ary, $cons );
			}
		}
	}

	if ( defined $block ) {
		return undef;
	}
	else {
		return $new_ary;
	}
}

=item each_entry()
  Passing each element in self as a parameter to the call block.
  Alias: each()
  
  ra(1, 2, 3)->each_entry(sub { print $_[0] }); #return ra(1, 2, 3)
=cut

sub each_entry {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		for my $item ( @{$self} ) {
			$block->($item);
		}
	}

	return $self;
}

=item each_index
  Passing the index of each element to the block.
  
  ra(1, 3, 5, 7)->each_index( sub { print $_[0] } ); # print 0123
=cut

sub each_index {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
		$block->($i);
	}

	return $self;
}

=item each_slice
  Group element with (n-1)  members in to an new array until the last element included.
  
  ra(1, 2, 3, 4, 5)->each_slice(3); #return ra(ra(1, 2, 3), ra(4, 5));
=cut

sub each_slice {
	my ( $self, $n, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	die 'ArgumentError: invalid slice size'
	  if ( ( not defined $n ) || $n <= 0 );

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	my $blocks =
	  scalar( @{$self} ) % $n == 0
	  ? int( scalar( @{$self} ) / $n )
	  : int( scalar( @{$self} ) / $n ) + 1;
	for ( my $i = 0 ; $i < $blocks ; $i++ ) {
		my $cons = tie my @cons, 'Ruby::Collections::Array';
		for (
			my $j = $i * $n ;
			$j < scalar( @{$self} ) ? $j < $i * $n + $n : undef ;
			$j++
		  )
		{
			$cons->push( $self->at($j) );
		}
		if ( defined $block ) {
			$block->($cons);
		}
		else {
			push( @new_ary, $cons );
		}
	}

	if ( defined $block ) {
		return undef;
	}
	else {
		return $new_ary;
	}
}

=item each_with_index
  For each item calls block with itself and it's index.
  
  ra(1, 2, 3)->each_with_index(sub { $_[1] }); #return ra(0, 1, 2)
=cut

sub each_with_index {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
			$block->( @{$self}[$i], $i );
		}
	}

	return $self;
}

=item each_with_object
  Passing each element with an object in a block, return the object in the end.
  
  ra( 1, 2, 3 )->each_with_object( ra, sub { $_[1] << $_[0]**2 } ); #return ra( 1, 4, 9 )
  
=cut

sub each_with_object {
	my ( $self, $object, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		for my $item ( @{$self} ) {
			$block->( $item, $object );
		}
	}

	return $object;
}

=item is_empty
  Return true if the array don't contain any element.
  
  ra(1, 2, 3)->is_empty() #return 0;
=cut

sub is_empty {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( scalar( @{$self} ) == 0 ) {
		return 1;
	}
	else {
		return 0;
	}
}

=item eql
  Return true if these 2 arrays have same order and content.
  
  ra(1, 2, 3)->equal(ra(4, 5, 6)) #return 0
=cut

sub eql {
	my ( $self, $other ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( reftype($other) ne 'ARRAY' ) {
		return 0;
	}

	if ( scalar( @{$self} ) != scalar( @{$other} ) ) {
		return 0;
	}

	for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
		if ( p_obj( @{$self}[$i] ) ne p_obj( @{$other}[$i] ) ) {
			return 0;
		}
	}

	return 1;
}

=item not_eql
  Return true if these 2 arrays have different order and content.
  
  ra(1, 2, 3)->not_equal(ra(4, 5, 6)) #return 1
=cut

sub not_eql {
	my ( $self, $other ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->eql($other) == 0 ? 1 : 0;
}

=item fetch()
  Retrun the element of array from given index.
  If the given index is out of the scalar of array, it will be seen as an IndexError exception, 
  unless a second argument is given, and which will be a default value.
  If a block is given, it will be executed when an invalid index is given.
  If the index is a negative value, the last element of array will be return.
  
  ra(1, 2, 3)->fetch(2) #return 3;
  ra(1, 2, 3)->fetch(5, 6) #return 6;
  ra(1, 2, 3)->fetch(-1) #return 3;
=cut

sub fetch {
	my ( $self, $index, $default_value_or_block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( $index >= scalar( @{$self} ) || $index < -scalar( @{$self} ) ) {
		if ( defined $default_value_or_block ) {
			if ( ref($default_value_or_block) eq 'CODE' ) {
				return $default_value_or_block->($index);
			}
			else {
				return $default_value_or_block;
			}
		}
		else {
			die(    "index "
				  . $index
				  . " outside of array bounds: "
				  . -scalar( @{$self} ) . "..."
				  . scalar( @{$self} ) );
		}
	}
	return $self->at($index);
}

=item fill
  Replace all the elements in array by the given value.
  If the second and third(n) value are given in the same time, means the array will be replace by the given value
  from the second value of index to the following n elements.
  If a block is given, it will pass all or given amount of indexs to the block and return the result as an array.
  
  ra(1, 2, 3)->fill(4) #return ra(4, 4, 4);
  ra(1, 2, 3, 4)->fill(sub {$_[0]}) #return ra(0, 1, 2, 3);
  ra(1, 2, 3, 4)->fill(1, sub { 11 }) #return ra(1, 11, 11, 11);
  ra(1, 2, 3, 4)->fill('ab', 1) #return ra(1, 'ab', 'ab', 'ab');
  ra(1, 2, 3, 4)->fill(1, 2, sub { 11 }) #return ra(1, 11, 11, 4);
  ra(1, 2, 3, 4)->fill('ab', 1, 2) #return ra(1, 'ab', 'ab', 4);
=cut

sub fill {
	if ( @_ == 2 ) {
		if ( ref( $_[1] ) eq 'CODE' ) {
			my ( $self, $block ) = @_;
			ref($self) eq __PACKAGE__ or die;

			for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
				@{$self}[$i] = $block->($i);
			}

			return $self;
		}
		else {
			my ( $self, $item ) = @_;
			ref($self) eq __PACKAGE__ or die;

			for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
				@{$self}[$i] = $item;
			}

			return $self;
		}
	}
	elsif ( @_ == 3 ) {
		if ( ref( $_[2] ) eq 'CODE' ) {
			my ( $self, $start, $block ) = @_;
			ref($self) eq __PACKAGE__ or die;

			for ( my $i = $start ; $i < scalar( @{$self} ) ; $i++ ) {
				@{$self}[$i] = $block->($i);
			}

			return $self;
		}
		else {
			my ( $self, $item, $start ) = @_;
			ref($self) eq __PACKAGE__ or die;

			for ( my $i = $start ; $i < scalar( @{$self} ) ; $i++ ) {
				@{$self}[$i] = $item;
			}

			return $self;
		}
	}
	elsif ( @_ == 4 ) {
		if ( ref( $_[3] ) eq 'CODE' ) {
			my ( $self, $start, $length, $block ) = @_;
			ref($self) eq __PACKAGE__ or die;

			for ( my $i = $start ; $i < $start + $length ; $i++ ) {
				@{$self}[$i] = $block->($i);
			}
			return $self;
		}
		else {
			my ( $self, $item, $start, $length ) = @_;
			ref($self) eq __PACKAGE__ or die;

			for ( my $i = $start ; $i < $start + $length ; $i++ ) {
				@{$self}[$i] = $item;
			}

			return $self;
		}
	}
}

=item find
  Passing each element to the block, and return the first element if block is true, else return undef.
  
  ra('a', 'b', 'c', 'b')->find(sub { $_[0] eq 'b' }) return b;
=cut

sub find {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	for my $item ( @{$self} ) {
		if ( $block->($item) ) {
			return $item;
		}
	}

	return undef;
}

*detect = \&find;

=item find_index
  Return the first index of the given value in the array.
  If a block instead of an argument, then return the first index of the given value in the array.
  
  ra('a', 'b', 'c', 'b')->find_index('b') #return 1;
  ra('a', 'b', 'c', 'b')->find_index( sub { if($_[0] eq 'b')}) #return 1;
=cut

sub find_index {
	my ( $self, $obj_or_block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( ref($obj_or_block) eq 'CODE' ) {
		for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
			return $i if ( $obj_or_block->( @{$self}[$i] ) );
		}
	}
	else {
		for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
			return $i
			  if ( p_obj( @{$self}[$i] ) eq p_obj($obj_or_block) );
		}
	}

	return undef;
}

=item index
  Retrun the first index of given object in array.
  
  ra('a', 'b', 'c', 'c')->index('c') #return 2; 
=cut

sub index {
	my ( $self, $obj_or_block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( ref($obj_or_block) eq 'CODE' ) {
		for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
			if ( $obj_or_block->( @{$self}[$i] ) ) {
				return $i;
			}
		}
	}
	else {
		for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
			if ( p_obj( @{$self}[$i] ) eq p_obj($obj_or_block) ) {
				return $i;
			}
		}
	}

	return undef;
}

=item inject
  Combines all elements by applying a binary operation, ex. a block, method or operator.
  
  ra(1, 2, 3, 4)->inject(sub { $_[0] + $_[1] }) #return 10;
=cut

sub inject {
	my $self = shift @_;
	ref($self) eq __PACKAGE__ or die;

	if ( @_ == 1 ) {
		my $block = shift @_;

		my $out = @{$self}[0];
		for ( my $i = 1 ; $i < scalar( @{$self} ) ; $i++ ) {
			$out = $block->( $out, @{$self}[$i] );
		}

		return $out;
	}
	elsif ( @_ == 2 ) {
		my ( $init, $block ) = @_;

		my $out = $init;
		for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
			$out = $block->( $out, @{$self}[$i] );
		}

		return $out;
	}
	else {
		die 'ArgumentError: wrong number of arguments (' . @_ . ' for 0..2)';
	}
}

*reduce = \&inject;

=item first
  Return the first or first n elements of the array.
  Return the first n elements of the array as a new array.
  
  ra(1, 2, 3 ,4)->first #return 1
  ra(1, 2, 3 ,4)->first(2) #return ra(1, 2)
=cut

sub first {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $n ) {
		die 'ArgumentError: negative array size' if ( $n < 0 );

		my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
		for ( my $i ; $i < $n && $i < scalar( @{$self} ) ; $i++ ) {
			push( @new_ary, @{$self}[$i] );
		}
		return $new_ary;
	}
	else {
		return @{$self}[0];
	}
}

=item flat_map()
  Return a new array with the concatenated result of each element's running block.

  ra(ra('a', 'b', 'c'), ra('d', 'e'))->flat_map(sub {$_[0] + ra('f')}) #return ra('a', 'b', 'c', 'f', 'd', 'e', 'f');
=cut

sub flat_map {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	$self->map($block)->each(
		sub {
			if ( reftype( $_[0] ) eq 'ARRAY' ) {
				if ( $_[0]->has_any( sub { reftype( $_[0] ) eq 'ARRAY' } ) ) {
					$new_ary->push( $_[0]->flatten(1) );
				}
				else {
					$new_ary->concat( $_[0] );
				}
			}
			else {
				$new_ary->push( $_[0] );
			}
		}
	);

	return $new_ary;
}

*collect_concat = \&flat_map;

=item flatten
  Return a new array after flattening self into one-dimension.
  
 ra(ra('a', 'b'), ra('d', 'e'))->flatten #return ra('a', 'b', 'd', 'e');
=cut

sub flatten {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	for my $item ( @{$self} ) {
		if ( defined $n && $n > 0 && reftype($item) eq 'ARRAY' ) {
			$new_ary->concat( recursive_flatten( $item, $n - 1 ) );
		}
		elsif ( !defined $n && reftype($item) eq 'ARRAY' ) {
			$new_ary->concat( recursive_flatten($item) );
		}
		else {
			push( @new_ary, $item );
		}
	}

	return $new_ary;
}

=item recursive_flatten
  
=cut

sub recursive_flatten {
	caller eq __PACKAGE__ or die;
	my ( $ary, $n ) = @_;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	for my $item ( @{$ary} ) {
		if ( defined $n && $n > 0 && reftype($item) eq 'ARRAY' ) {
			$new_ary->concat( recursive_flatten( $item, $n - 1 ) );
		}
		elsif ( !defined $n && reftype($item) eq 'ARRAY' ) {
			$new_ary->concat( recursive_flatten($item) );
		}
		else {
			push( @new_ary, $item );
		}
	}

	return $new_ary;
}

=item flattenEx()
  Flattens self in place.
  
  ra(ra('a', 'b'), ra('d', 'e'))->flattenEx #return ra('a', 'b', 'd', 'e');
=cut

sub flattenEx {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	for my $item ( @{$self} ) {
		if ( defined $n && $n > 0 && reftype($item) eq 'ARRAY' ) {
			$new_ary->concat( recursive_flatten( $item, $n - 1 ) );
		}
		elsif ( !defined $n && reftype($item) eq 'ARRAY' ) {
			$new_ary->concat( recursive_flatten($item) );
		}
		else {
			push( @new_ary, $item );
		}
	}
	@{$self} = @new_ary;

	return $self;
}

=item grep()
  Return all the elements as an array which matches the given pattern.
  If a block is supplied, each matching element will be passed to the block, and the result will be collect in an array.
  
  ra('abbc', 'qubbn', 'accd')->grep('bb') #return ra('abbc', 'qubbn')
  ra('abbc', 'qubbn', 'accd')->grep('bb', sub { $_[0] + 'l'}) #return ra('abbcl', 'qubbnl')
=cut

sub grep {
	my ( $self, $pattern, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	for my $item ( @{$self} ) {
		if ( p_obj($item) =~ $pattern ) {
			if ( defined $block ) {
				push( @new_ary, $block->($item) );
			}
			else {
				push( @new_ary, $item );
			}
		}
	}

	return $new_ary;
}

=item group_by
  Return a hash which key is the block result and the values are arrays of elements which related with the key.
  
  ra(1, 2, 3, 4)->group_by( sub { $_[0]%3 }) #return rh( 1=>[1, 4], 2=>[2], 0=>[3]);
=cut

sub group_by {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_hash = tie my %new_hash, 'Ruby::Collections::Hash';
	for my $item ( @{$self} ) {
		my $key = $block->($item);
		if ( $new_hash->{$key} ) {
			$new_hash->{$key}->push($item);
		}
		else {
			$new_hash->{$key} = tie my @group, 'Ruby::Collections::Array';
			$new_hash->{$key}->push($item);
		}
	}

	return $new_hash;
}

=iten include()
  Return true if any element equals the given object.
  
  ra(1, 3, 5, 7, 9)->include(9) #return true #
=cut

sub include {
	my ( $self, $obj ) = @_;
	ref($self) eq __PACKAGE__ or die;

	for my $item ( @{$self} ) {
		if ( p_obj($item) eq p_obj($obj) ) {
			return 1;
		}
	}

	return 0;
}

*has_member = \&include;

=item replace()
  Replace all elements of self by the other elements of given array.
  
  ra(1, 4, 6)->replace(ra(2, 5)) #return ra(2, 5);
=cut

sub replace {
	my ( $self, $other_ary ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( reftype($other_ary) eq 'ARRAY' ) {
		@{$self} = @{$other_ary};
	}
	else {
		die 'TypeError: no implicit conversion of '
		  . reftype($other_ary)
		  . ' into Array';
	}

	return $self;
}

=item insert()
  Insert the given value at the given index.
  
  ra(1, 2, 3, 4)->insert(2, 5) #return ra(1, 2, 5, 3, 4);
  ra(1, 2, 3 ,4)->insert(-2, 5) #return ra(1, 2, 3, 5, 4);#
=cut

sub insert {
	my $self  = shift(@_);
	my $index = shift(@_);

	if ( $index < -scalar( @{$self} ) ) {
		die(    "IndexError: index "
			  . $index
			  . " too small for array; minimum: "
			  . -scalar( @{$self} ) );
	}
	elsif ( $index > scalar( @{$self} ) ) {
		for ( my $i = scalar( @{$self} ) ; $i < $index ; $i++ ) {
			push( @{$self}, undef );
		}
		splice( @{$self}, $index, 0, @_ );
	}
	else {
		splice( @{$self}, $index < 0 ? $index + 1 : $index, 0, @_ );
	}

	return $self;
}

=item inspect()
  Return the object as string.
  
  ra(1, 2, 3)->inspect() #return 'ra(1, 2, 3)'; #
=cut

sub inspect {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	return p_array $self;
}

=item to_s()
  ra(1, 2, 3)->inspect() #return 'ra(1, 2, 3)';
=cut

sub to_s {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->inspect;
}

=item join()
  Return a string created by converting each element of array to a string, merged by the given separator.
  
  ra('a', 'b', 'c')->join("/") #return 'a/b/c';
=cut

sub join {
	my ( $self, $separator ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $separator ) {
		return join( $separator, @{$self} );
	}
	else {
		return join( '', @{$self} );
	}
}

=item keep_if()
  Delete the element of self for which the given block evaluates to false.
  
  ra(1, 2, 3)->keep_if(sub {$_[0] > 2}) #return ra(3);
=cut

sub keep_if {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	@{$self} = grep { $block->($_) } @{$self};

	return $self;
}

=item last()
  Return the last or last n elements of self.
  
  ra(1, 2, 3)->last #return 3;
  ra(1, 2, 3)->last(2) #return ra(2, 3);
=cut

sub last {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $n ) {
		my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
		for (
			my $i = scalar( @{$self} ) - 1 ;
			$i >= 0 && $i > scalar( @{$self} ) - 1 - $n ;
			$i--
		  )
		{
			unshift( @new_ary, @{$self}[$i] );
		}
		return $new_ary;
	}
	else {
		return @{$self}[-1];
	}
}

=item length()
  Retrun the number of elements of self.
  
  ra(1, 2, 3)->length() #return 3;
  ra()->length() #return 0;
=cut

sub length {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	return scalar( @{$self} );
}

*size = \&length;

=item map()
  Transform each element and store them into a new Ruby::Collections::Array.
  Alias: collect()
=cut

sub map {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	for my $item ( @{$self} ) {
		push( @new_ary, $block->($item) );
	}

	return $new_ary;
}

*collect = \&map;

=item mapEx()
  Transform each element and store them in self.
  Alias: collectEx()
=cut

sub mapEx {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my @new_ary;
	for my $item ( @{$self} ) {
		push( @new_ary, $block->($item) );
	}
	@{$self} = @new_ary;

	return $self;
}

*collectEx = \&mapEx;

=item max()
  Return the max value of object.
  If a block is given, 
  
  ra(1, 2, 3)->max() #return 3;
  ra(1, 2, 3)->max(sub {$_[1] <=> $_[0]}) #return 1;
=cut

sub max {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		return $self->sort($block)->last;
	}
	else {
		return $self->sort->last;
	}
}

=item max_by()
  Return the object that gives the maximum value from the given block.
  
  ra('avv', 'aldivj', 'kgml')->max_by(sub {length($_[0])}) #return 'aldivj';
=cut

sub max_by {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->sort_by($block)->last;
}

=item min()
  Return the min value of object.
  If a block is given, 
  
  ra(1, 2, 3)->min() #return 1;
  ra(1, 2, 3)->min(sub {$_[1] <=> $_[0]}) #return 3;
=cut

sub min {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		return $self->sort($block)->first;
	}
	else {
		return $self->sort->first;
	}
}

=item min_by()
  Return the object that gives the minimum value from the given block.
  
  ra('kv', 'aldivj', 'kgml')->min_by(sub {length($_[0])}) #return 'kv';
=cut

sub min_by {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->sort_by($block)->first;
}

=item minmax()
  Return an array which contains the minimum and maximum value.
  
  ra(1, 2, 3)->minmax #return ra(1, 3);
  ra('bbb', 'foekvv', 'rd')->minmax(sub{length($_[0]) <=> length($_[1])}) #return ra('rd', 'foekvv'); 
=cut

sub minmax {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
		my $sorted_ary = $self->sort($block);
		$new_ary->push( $sorted_ary->first );
		$new_ary->push( $sorted_ary->last );
		return $new_ary;
	}
	else {
		my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
		my $sorted_ary = $self->sort();
		$new_ary->push( $sorted_ary->first );
		$new_ary->push( $sorted_ary->last );
		return $new_ary;
	}
}

=item minmax_by()
  Return an array which contains the objects that correspond to the minimum and maximum value respectively from the given block.
  
  ra('heard', 'see', 'thinking')->minmax_by(sub {length($_[0])}) #return ra('see', 'thinking');
=cut

sub minmax_by {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	my $sorted_ary = $self->sort_by($block);
	$new_ary->push( $sorted_ary->first );
	$new_ary->push( $sorted_ary->last );
	return $new_ary;
}

=item has_none()
  Pass each element to the given block, this method returns true if the block never returns true for all elements.
  If the block is not given, this method returns true if all the elements are flase.
  
  ra(99, 43, 65)->has_none(sub {$_[0] < 50}) #return 0;
  ra()->has_none #return 1;
=cut

sub has_none {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		for my $item ( @{$self} ) {
			return 0 if ( $block->($item) );
		}
	}
	else {
		for my $item ( @{$self} ) {
			return 0 if ($item);
		}
	}

	return 1;
}

=item has_one()
  Pass each element to the given block, this method returns true if the block returns true exactly once.
  If the block is not given, this method returns true if only one elements is true.
  
  ra(99, 43, 65)->has_one(sub {$_[0] < 50}) #return 1;
  ra(100)->has_one #return 1;
=cut

sub has_one {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $count = 0;
	if ( defined $block ) {
		for my $item ( @{$self} ) {
			if ( $block->($item) ) {
				$count++;
				return 0 if ( $count > 1 );
			}
		}
	}
	else {
		for my $item ( @{$self} ) {
			if ($item) {
				$count++;
				return 0 if ( $count > 1 );
			}
		}
	}

	return $count == 1 ? 1 : 0;
}

=item partition()
  Return an array which contains two elements.
  The first are the objects which evaluate the block to true.
  The second are the rest.
  
  ra(1, 2, 3, 4, 5, 6, 7)->partition(sub {$_[0] % 2 == 0}) #return ra(ra(2, 4, 6), ra(1, 3, 5, 7));
=cut

sub partition {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary   = tie my @new_ary,   'Ruby::Collections::Array';
	my $true_ary  = tie my @true_ary,  'Ruby::Collections::Array';
	my $false_ary = tie my @false_ary, 'Ruby::Collections::Array';

	for my $item ( @{$self} ) {
		if ( $block->($item) ) {
			push( @true_ary, $item );
		}
		else {
			push( @false_ary, $item );
		}
	}
	push( @new_ary, $true_ary, $false_ary );

	return $new_ary;
}

=item permutation()
  If a block is given, then return self as all kind of permutations.
  If a parameter(n) is given, and also a block, then return self as all kind of permutations in length n.
  If a block is not given, then return 
  
  ra(1, 2, 3)->permutation()
=cut

sub permutation {
	my ( $self, $n, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $combinat =
	  Math::Combinatorics->new( count => $n, data => [ @{$self} ] );

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	if ( $n < 0 ) {
		if ( defined $block ) {
			return $self;
		}
		else {
			return $new_ary;
		}
	}
	if($n == undef) {
		$n = $self->size();
	}
	if ( $n == 0 ) {
		if ( defined $block ) {
			$block->( tie my @empty_ary, 'Ruby::Collections::Array' );
			return $self;
		}
		else {
			push( @new_ary, tie my @empty_ary, 'Ruby::Collections::Array' );
			return $new_ary;
		}
	}

	my $combos = $self->combination($n);
	for my $combo ( @{$combos} ) {
		my $combinat =
		  Math::Combinatorics->new( count => $n, data => [ @{$combo} ] );
		while ( my @permu = $combinat->next_permutation ) {
			my $p = tie my @p, 'Ruby::Collections::Array';
			@p = @permu;
			if ( defined $block ) {
				$block->($p);
			}
			else {
				push( @new_ary, $p );
			}
		}
	}

	if ( defined $block ) {
		return $self;
	}
	else {
		return $new_ary;
	}
}

=item pop()
  Return the last element.
  If a number n is given, then return the last n elements as an array.
  
  ra(1, 2, 3)->pop #return 3;
  ra(1, 2, 3)->pop(2) #return ra(2, 3);
=cut

sub pop {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $n ) {
		die 'ArgumentError: negative array size' if ( $n < 0 );

		my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
		for ( my $i ; $i < $n && scalar( @{$self} ) != 0 ; $i++ ) {
			unshift( @new_ary, pop( @{$self} ) );
		}
		return $new_ary;
	}
	else {
		return pop( @{$self} );
	}
}

=item product()
  Return an array of all combinations of all arrays.
  #block
  
  ra(1, 2)->product(ra(2,3)) #return ra(ra(1, 2), ra(1, 3), ra(2, 2), ra(2, 3));
=cut

sub product {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $block = undef;
	if ( ref( $_[-1] ) eq 'CODE' ) {
		$block = pop @_;
	}

	my $array_of_arrays = [];
	for my $item (@_) {
		my @array = @{$item};
		push( @{$array_of_arrays}, \@array );
	}

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	my $iterator = Set::CrossProduct->new($array_of_arrays);
	while ( $iterator->next ) {
		my $tuple = tie my @tuple, 'Ruby::Collections::Array';
		@tuple = @{ $iterator->get };
		if ( defined $block ) {
			$block->($tuple);
		}
		else {
			push( @new_ary, $tuple );
		}
	}

	if ( defined $block ) {
		return $self;
	}
	else {
		return $new_ary;
	}
}

=item push()
  Appending the given array to self, then return it.
  
  ra(1, 2, 3)->push(5, 6) #return ra(1, 2, 3, 5, 6);
=cut

sub push {
	my $self = shift @_;
	ref($self) eq __PACKAGE__ or die;

	push( @{$self}, @_ );

	return $self;
}

=item double_left_arrows()
  Alias : push()
=cut

sub double_left_arrows {
	my $self = shift @_;
	ref($self) eq __PACKAGE__ or die;

	push( @{$self}, $_[0] );

	return $self;
}

=item rassoc()
  Returns the first array which contains the target object as the last element.
  
  ra(ra(1, 3), 3, ra(2, 3))->rassoc(3) #returns ra(1, 3);
=cut

sub rassoc {
	my ( $self, $target ) = @_;
	ref($self) eq __PACKAGE__ or die;

	for my $item ( @{$self} ) {
		if ( reftype($item) eq 'ARRAY' ) {
			my @sub_array = @{$item};
			if ( p_obj( $sub_array[-1] ) eq p_obj($target) ) {
				my $ret = tie my @ret, 'Ruby::Collections::Array';
				@ret = @sub_array;
				return $ret;
			}
		}
	}

	return undef;
}

=item reject()
  Return a new array contains the elements from self for which the given block is not true.
  Alias: delete_if()
  
  ra(1, 2, 3)->reject(sub { $_[0] < 3 }) #return ra(3);
=cut

sub reject {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	@new_ary = grep { !$block->($_) } @{$self};

	return $new_ary;
}

=item rejectEx()
  Delete all the elements from self for which the given block is true.
  
  ra(1, 2, 3)->rejectEx(sub { $_[0] < 3 }) #return ra(3);
=cut

sub rejectEx {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $before_len = scalar( @{$self} );
	@{$self} = grep { !$block->($_) } @{$self};

	if ( scalar( @{$self} ) == $before_len ) {
		return undef;
	}
	else {
		return $self;
	}
}

=item repeated_combination()
  Returns the array which lists all the repeated combinations of length n of all elements from array.
  
  ra(1, 2, 3)->repeated_combination(2) #returns ra(ra(1, 1), ra(1, 2), ra(1, 3), ra(2, 2), ra(2, 3), ra(3, 3));
=cut

sub repeated_combination {
	my ( $self, $n, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	if ( $n < 0 ) {
		if ( defined $block ) {
			return $self;
		}
		else {
			return $new_ary;
		}
	}
	if ( $n == 0 ) {
		if ( defined $block ) {
			$block->( tie my @empty_ary, 'Ruby::Collections::Array' );
			return $self;
		}
		else {
			push( @new_ary, tie my @empty_ary, 'Ruby::Collections::Array' );
			return $new_ary;
		}
	}

	repeated_combination_loop(
		$n, 0,
		scalar( @{$self} ) - 1,
		sub {
			my $comb = tie my @comb, 'Ruby::Collections::Array';
			for ( my $i = 0 ; $i < scalar( @{ $_[0] } ) ; $i++ ) {
				push( @comb, @{$self}[ @{ $_[0] }[$i] ] );
			}
			if ( defined $block ) {
				$block->($comb);
			}
			else {
				push( @new_ary, $comb );
			}
		}
	);

	if ( defined $block ) {
		return $self;
	}
	else {
		return $new_ary;
	}
}


sub repeated_combination_loop {
	caller eq __PACKAGE__ or die;

	my ( $layer, $start, $end, $block ) = @_;
	my @counter      = ($start) x $layer;
	my $loop_counter = \@counter;

	my @end_status = ($end) x scalar(@$loop_counter);
	do {
		$block->($loop_counter);
		increase_repeated_combination_loop_counter( $loop_counter, $start,
			$end );
	} until ( "@$loop_counter" eq "@end_status" );
	$block->($loop_counter);
}

=item increase_repeated_combination_loop_counter()
=cut

sub increase_repeated_combination_loop_counter {
	caller eq __PACKAGE__ or die;

	my ( $loop_counter, $start, $end ) = @_;

	for my $i ( reverse( 0 .. scalar(@$loop_counter) - 1 ) ) {
		if ( $loop_counter->[$i] < $end ) {
			$loop_counter->[$i]++;
			last;
		}
		elsif ( $i != 0
			and $loop_counter->[ $i - 1 ] != $end )
		{
			$loop_counter->[ $i - 1 ]++;
			for my $j ( $i .. scalar(@$loop_counter) - 1 ) {
				$loop_counter->[$j] = $loop_counter->[ $i - 1 ];
			}
			last;
		}
	}
}

=item repeated_permutation()
  Returns the array which lists all the repeated permutations of length n of all elements from array.
  
  ra(1, 2)->repeated_permutation(2) #returns ra(ra(1, 1), ra(1, 2), ra(2, 1), ra(2, 2));
=cut

sub repeated_permutation {
	my ( $self, $n, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	if ( $n < 0 ) {
		if ( defined $block ) {
			return $self;
		}
		else {
			return $new_ary;
		}
	}
	if ( $n == 0 ) {
		if ( defined $block ) {
			$block->( tie my @empty_ary, 'Ruby::Collections::Array' );
			return $self;
		}
		else {
			push( @new_ary, tie my @empty_ary, 'Ruby::Collections::Array' );
			return $new_ary;
		}
	}

	repeated_permutation_loop(
		$n, 0,
		scalar( @{$self} ) - 1,
		sub {
			my $comb = tie my @comb, 'Ruby::Collections::Array';
			for ( my $i = 0 ; $i < scalar( @{ $_[0] } ) ; $i++ ) {
				push( @comb, @{$self}[ @{ $_[0] }[$i] ] );
			}
			if ( defined $block ) {
				$block->($comb);
			}
			else {
				push( @new_ary, $comb );
			}
		}
	);

	if ( defined $block ) {
		return $self;
	}
	else {
		return $new_ary;
	}
}

sub repeated_permutation_loop {
	caller eq __PACKAGE__ or die;

	my ( $layer, $start, $end, $block ) = @_;
	my @counter      = ($start) x $layer;
	my $loop_counter = \@counter;

	my @end_status = ($end) x scalar(@$loop_counter);
	do {
		$block->($loop_counter);
		increase_repeated_permutation_loop_counter( $loop_counter, $start,
			$end );
	} until ( "@$loop_counter" eq "@end_status" );
	$block->($loop_counter);
}

sub increase_repeated_permutation_loop_counter {
	caller eq __PACKAGE__ or die;

	my ( $loop_counter, $start, $end ) = @_;

	for my $i ( reverse( 0 .. scalar(@$loop_counter) - 1 ) ) {
		if ( $loop_counter->[$i] < $end ) {
			$loop_counter->[$i]++;
			last;
		}
		elsif ( $i != 0
			and $loop_counter->[ $i - 1 ] != $end )
		{
			$loop_counter->[ $i - 1 ]++;
			for my $j ( $i .. scalar(@$loop_counter) - 1 ) {
				$loop_counter->[$j] = $start;
			}
			last;
		}
	}
}

=item reverse()
  Returns a new array which contains self's elements in the reverse order.
  
  ra(1, 2, 3)->reverse() #returns ra(3, 2, 1);
=cut

sub reverse {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	@new_ary = reverse( @{$self} );

	return $new_ary;
}

=item reverseEx()
  Returns self where all the elements list in the reverse order.
  
  ra(1, 2, 3)->reverseEx() #returns ra(3, 2, 1);
=cut

sub reverseEx {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	@{$self} = reverse( @{$self} );

	return $self;
}

=item reverse_each()
  Passing all the elements to the block, but in the reverse order.
  
  ra(1, 2, 3)->reverse_each(sub {$_[0]}) #returns ra(3, 2, 1);
=cut

sub reverse_each {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = $self->reverse;
	if ( defined $block ) {
		for my $item ($new_ary) {
			$block->($item);
		}
	}

	return $new_ary;
}

=item rindex()
  Returns the index of last object which equal to given object.
  If a block is given, returns the index of the last object for which the block returns true.
  
  ra(1, 2, 3, 2, 4)->rindex(2) #returns 3;
  ra(1, 2, 3, 2, 4)->rindex(sub {$_[0] == 2}) #returns 3;
=cut

sub rindex {
	my ( $self, $obj_or_block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( ref($obj_or_block) eq 'CODE' ) {
		for ( my $i = scalar( @{$self} ) - 1 ; $i >= 0 ; $i-- ) {
			if ( $obj_or_block->( @{$self}[$i] ) ) {
				return $i;
			}
		}
	}
	else {
		for ( my $i = scalar( @{$self} ) - 1 ; $i >= 0 ; $i-- ) {
			if ( p_obj( @{$self}[$i] ) eq p_obj($obj_or_block) ) {
				return $i;
			}
		}
	}

	return undef;
}

=item rotate()
  Returns a new array by rotating self, the element at given number is the first element of new array.
  If the given number is negative, then statring from the end of self.
  
  ra(1, 2, 3)->rotate() #return ra(2, 3, 1);
  ra(1, 2, 3)->rotate(2) #return ra(3, 1, 2);
  ra(1, 2, 3)->rotate(-2) #return ra(2, 3, 1);
=cut

sub rotate {
	my ( $self, $count ) = @_;
	ref($self) eq __PACKAGE__ or die;

	$count = 1 if ( not defined $count );

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	@new_ary = @{$self};
	if ( scalar( @{$self} ) > 0 ) {
		while ( $count != 0 ) {
			if ( $count > 0 ) {
				$new_ary->push( $new_ary->shift );
				$count--;
			}
			elsif ( $count < 0 ) {
				$new_ary->unshift( $new_ary->pop );
				$count++;
			}
		}
	}

	return $new_ary;
}

=item rotateEx()
  See rotate, but return self inplace.
=cut

sub rotateEx {
	my ( $self, $count ) = @_;
	ref($self) eq __PACKAGE__ or die;

	$count = 1 if ( not defined $count );

	if ( scalar( @{$self} ) > 0 ) {
		while ( $count != 0 ) {
			if ( $count > 0 ) {
				$self->push( $self->shift );
				$count--;
			}
			elsif ( $count < 0 ) {
				$self->unshift( $self->pop );
				$count++;
			}
		}
	}

	return $self;
}

=item sample()
  Chooses a random element or n random elements from the array.
  
  ra(1, 2, 3, 4)->sample 
  ra(1, 2, 3, 4)->sample(2)
=cut

sub sample {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $n ) {
		die 'ArgumentError: negative array size' if ( $n < 0 );

		my $index_ary = tie my @index_ary, 'Ruby::Collections::Array';
		my $new_ary   = tie my @new_ary,   'Ruby::Collections::Array';

		$self->each_index( sub { $index_ary->push( $_[0] ); } );
		for ( my $i = 0 ; $i < $n && scalar(@index_ary) != 0 ; $i++ ) {
			$new_ary->push(
				@{$self}[
				  $index_ary->delete_at(
					  int( rand( scalar( @{$index_ary} ) ) )
				  )
				]
			);
		}

		return $new_ary;
	}
	else {
		return @{$self}[ int( rand( scalar( @{$self} ) ) ) ];
	}
}

=item select()
 Returns a new array which contains all the elements for which the given block returns true.
 
 ra(1, 4, 6, 7, 8)->select(sub {($_[0]%2) == 0 }) #return ra(4, 6, 8);
=cut

sub select {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	@new_ary = grep { $block->($_) } @{$self};

	return $new_ary;
}

*find_all = \&select;

=item selectEx()
  Deleting all the elements from self for which the given block returns false, then returns self.
  Alias : keep_if
  
  ra(1, 4, 6, 7, 8)->selectEx(sub {($_[0]%2) == 0 }) #return ra(4, 6, 8);
=cut

sub selectEx {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $before_len = scalar( @{$self} );
	@{$self} = grep { $block->($_) } @{$self};

	if ( scalar( @{$self} ) == $before_len ) {
		return undef;
	}
	else {
		return $self;
	}
}

=item shift()
  Removes the first element of self and returns it.
  If a number n is given, then removes the first n element of self and returns them as an array.
  
  ra(1, 2, 3)->shift #returns 1;
  ra(1, 2, 3, 4, 5)->shift(3) #returns ra(1, 2, 3);
=cut

sub shift {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $n ) {
		die 'ArgumentError: negative array size' if ( $n < 0 );

		my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
		for ( my $i ; $i < $n && scalar( @{$self} ) != 0 ; $i++ ) {
			push( @new_ary, shift( @{$self} ) );
		}
		return $new_ary;
	}
	else {
		return shift( @{$self} );
	}
}

=item unshift()
  Adding the objects to the front of self.
  
  ra(2, 4, 6)->unshift(1, 3, 5) #returns ra(1, 3, 5, 2, 4 ,6);
=cut

sub unshift {
	my $self = shift @_;
	ref($self) eq __PACKAGE__ or die;

	unshift( @{$self}, @_ );

	return $self;
}

=item shuffle()
  Returns a new array with all elements of self shuffled.
  
  ra(1, 2, 3, 4, 5, 6)->shuffle 
=cut

sub shuffle {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $index_ary   = tie my @index_ary,   'Ruby::Collections::Array';
	my $shuffle_ary = tie my @shuffle_ary, 'Ruby::Collections::Array';
	my $new_ary     = tie my @new_ary,     'Ruby::Collections::Array';

	$self->each_index( sub { $index_ary->push( $_[0] ); } );
	while ( scalar(@index_ary) != 0 ) {
		$shuffle_ary->push(
			$index_ary->delete_at( int( rand( scalar(@index_ary) ) ) ) );
	}
	for my $i (@shuffle_ary) {
		$new_ary->push( @{$self}[$i] );
	}

	return $new_ary;
}

=item shuffleEx()
  Shuffles all elements in self in place.
  
  ra(1, 2, 3, 4, 5, 6)->shuffleEx  
=cut

sub shuffleEx {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $index_ary   = tie my @index_ary,   'Ruby::Collections::Array';
	my $shuffle_ary = tie my @shuffle_ary, 'Ruby::Collections::Array';
	my $new_ary     = tie my @new_ary,     'Ruby::Collections::Array';

	$self->each_index( sub { $index_ary->push( $_[0] ); } );
	while ( scalar(@index_ary) != 0 ) {
		$shuffle_ary->push(
			$index_ary->delete_at( int( rand( scalar(@index_ary) ) ) ) );
	}
	for my $i (@shuffle_ary) {
		$new_ary->push( @{$self}[$i] );
	}
	@{$self} = @new_ary;

	return $self;
}

=item slice()
  Returns the element at given index.
  If the start and length(n) are given, then returns a new array contains the elements 
  from the start index to following n-1 elements.
  
  ra(1, 2, 3)->slice(2) #returns 3;
  ra(1, 2, 3, 4, 5)->slice(1, 2) #returns ra(2, 3);
=cut

sub slice {
	my ( $self, $index, $length ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $length ) {
		if ( $index < -scalar( @{$self} ) || $index >= scalar( @{$self} ) ) {
			return undef;
		}
		my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
		@new_ary = splice( @{$self}, $index, $length );
		return $new_ary;
	}
	else {
		return $self->at($index);
	}
}

=item sliceEx()
  Deleting the element at given index from self, then return this element.
  Or deleting the elements from given start index to following n-1 elements from self, then return these elements.
  
  ra(1, 2, 3)->slice(2) #returns 3;
  ra(1, 2, 3, 4, 5)->slice(1, 2) #returns ra(2, 3);
=cut

sub sliceEx {
	my ( $self, $index, $length ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $length ) {
		if ( $index < -scalar( @{$self} ) || $index >= scalar( @{$self} ) ) {
			return undef;
		}
		$index += scalar( @{$self} ) if ( $index < 0 );

		my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
		for ( my $i = $index ; $i < scalar( @{$self} ) && $length > 0 ; ) {
			$new_ary->push( $self->delete_at($i) );
			$length--;
		}

		return $new_ary;
	}
	else {
		return $self->delete_at($index);
	}
}

=item slice_before()
  Creates a new array for each chuncked elements, the method of chunks could by pattern or block.
  
  ra(1, 2, 3, 4, 5, 3)->slice_before(3) #returns ra(ra(1, 2), ra(3, 4, 5),ra(3));
  ra(1, 2, 3, 4, 5, 3)->slice_before(sub {$_[0]%3 == 0}) #returns ra(ra(1, 2), ra(3, 4, 5),ra(3));
=cut

sub slice_before {
	my $self = shift @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	my $group = undef;
	if ( ref( @_[0] ) eq 'CODE' ) {
		my $block = shift @_;

		for my $item ( @{$self} ) {
			if ( not defined $group ) {
				$group = tie my @group, 'Ruby::Collections::Array';
				push( @group, $item );
			}
			elsif ( $block->($item) ) {
				push( @new_ary, $group );
				$group = tie my @group, 'Ruby::Collections::Array';
				push( @group, $item );
			}
			else {
				push( @{$group}, $item );
			}
		}
	}
	else {
		my $pattern = shift @_;

		for my $item ( @{$self} ) {
			if ( not defined $group ) {
				$group = tie my @group, 'Ruby::Collections::Array';
				push( @group, $item );
			}
			elsif ( p_obj($item) =~ $pattern ) {
				push( @new_ary, $group );
				$group = tie my @group, 'Ruby::Collections::Array';
				push( @group, $item );
			}
			else {
				push( @{$group}, $item );
			}
		}
	}
	if ( defined $group && $group->has_any ) {
		push( @new_ary, $group );
	}

	return $new_ary;
}

=item sort()
  Returns a new array by sorting self.
  
  ra(1, 3, 5, 2, 7, 0)->sort #returns ra(0, 1, 2, 3, 5, 7);
  ra('djh', 'kdirhf', 'a')->sort(sub {length($_[0]) <=> length($_[1])}) #returns ra('a', 'djh', 'kdirhf');
=cut

sub sort {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	if ( defined $block ) {
		@new_ary = sort { $block->( $a, $b ) } @{$self};
	}
	else {
		@new_ary = sort {
			if (   looks_like_number( p_obj($a) )
				&& looks_like_number( p_obj($b) ) )
			{
				p_obj($a) <=> p_obj($b);
			}
			else {
				p_obj($a) cmp p_obj($b);
			}
		} @{$self};
	}

	return $new_ary;
}

=item sortEx()
  Sorts self in place.
  
  ra(1, 3, 5, 2, 7, 0)->sortEx #returns ra(0, 1, 2, 3, 5, 7);
  ra('djh', 'kdirhf', 'a')->sortEx(sub {length($_[0]) <=> length($_[1])}) #returns ra('a', 'djh', 'kdirhf');
=cut

sub sortEx {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		@{$self} = sort { $block->( $a, $b ) } @{$self};
	}
	else {
		@{$self} = sort {
			if (   looks_like_number( p_obj($a) )
				&& looks_like_number( p_obj($b) ) )
			{
				p_obj($a) <=> p_obj($b);
			}
			else {
				p_obj($a) cmp p_obj($b);
			}
		} @{$self};
	}

	return $self;
}

=item sort_by()
  Returns a new array by sorting self with block method.
  
  ra(2, 3, 7, 89, 6)->sort_by(sub {$_[0]-2}) #returns ra(2, 3, 6, 7, 89);
=cut

sub sort_by {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $trans_ary = tie my @trans_ary, 'Ruby::Collections::Array';
	for my $item ( @{$self} ) {
		push( @trans_ary, [ $block->($item), $item ] );
	}
	@trans_ary = sort {
		if (   looks_like_number( p_obj( @{$a}[0] ) )
			&& looks_like_number( p_obj( @{$b}[0] ) ) )
		{
			p_obj( @{$a}[0] ) <=> p_obj( @{$b}[0] );
		}
		else {
			p_obj( @{$a}[0] ) cmp p_obj( @{$b}[0] );
		}
	} @trans_ary;
	$trans_ary->mapEx( sub { return @{ $_[0] }[1]; } );

	return $trans_ary;
}

=item sort_byEx()
  Sorting self with block method, and return self.
  
  ra(2, 3, 7, 89, 6)->sort_byEx(sub {$_[0]-2}) #returns ra(2, 3, 6, 7, 89);
=cut

sub sort_byEx {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $trans_ary = tie my @trans_ary, 'Ruby::Collections::Array';
	for my $item ( @{$self} ) {
		push( @trans_ary, [ $block->($item), $item ] );
	}
	@trans_ary = sort {
		if (   looks_like_number( p_obj( @{$a}[0] ) )
			&& looks_like_number( p_obj( @{$b}[0] ) ) )
		{
			p_obj( @{$a}[0] ) <=> p_obj( @{$b}[0] );
		}
		else {
			p_obj( @{$a}[0] ) cmp p_obj( @{$b}[0] );
		}
	} @trans_ary;
	$trans_ary->mapEx( sub { return @{ $_[0] }[1]; } );
	@{$self} = @trans_ary;

	return $self;
}

=item take()
  Takes the first n elements from the array.
  
  ra(3, 5, 6, 7, 8, 9)->take(2) #returns ra(3, 5);
=cut

sub take {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $n ) {
		die 'ArgumentError: negative array size' if ( $n < 0 );

		my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
		for ( my $i ; $i < $n && $i < scalar( @{$self} ) ; $i++ ) {
			push( @new_ary, @{$self}[$i] );
		}
		return $new_ary;
	}
	else {
		die 'ArgumentError: wrong number of arguments (0 for 1)';
	}
}

=item take_while()
  Passes all elements to the block until the block is false, then returns the previous elements.
  
  ra(2, 4, 3 ,6 ,7 , 8, 2)->take_while(sub {$_[0] < 5}) #returns ra(2, 4, 3);
=cut

sub take_while {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	for my $item ( @{$self} ) {
		if ( $block->($item) ) {
			push( @new_ary, $item );
		}
		else {
			return $new_ary;
		}
	}

	return $new_ary;
}

=item to_a()
  Returns self.
  
  ra(2, 4, 6, 7, 8, 9)->to_a #returns ra(2, 4, 6, 7, 8, 9);
=cut

sub to_a {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self;
}

sub transpose {
	
}

=item entries()
  Returns an array containing all elements.
  
  rh(2=>4, 4=>5, 6=>7)->entries #returns ra(ra(2, 4),ra(4, 5) ,ra(6, 7));
=cut

sub entries {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	@new_ary = @{$self};

	return @new_ary;
}

=item zip()
  Converts all arguments into array, and merges each arrays with self by corresponding index.
  
  my $a = ra(1, 2, 3);
  my $b = ra(4, 5, 6);
  my $c = ra(7, 8);
  $a->zip($b) #returns ra(ra(1, 4), ra(2, 5), ra(3, 6));
  $a->zip($c) #returns ra(ra(1, 7), ra(2, 8), ra(3, undef));
=cut

sub zip {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;
	my $block = undef;
	$block = pop @_ if ( ref( $_[-1] ) eq 'CODE' );

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	for ( my $i = 0 ; $i < scalar( @{$self} ) ; $i++ ) {
		my $zip = tie my @zip, 'Ruby::Collections::Array';
		for my $ary (@_) {
			push( @zip, @{$ary}[$i] );
		}
		if ( defined $block ) {
			$block->($zip);
		}
		else {
			push( @new_ary, $zip );
		}
	}

	if ( defined $block ) {
		return undef;
	}
	else {
		return $new_ary;
	}
}

=item union()
  Returns a new array by joining with given array, and removing the duplicate elements.
  
  ra(1, 3, 4)->union(ra(2, 4, 6)) #returns ra(1, 3, 4, 2, 6);
=cut

sub union {
	my ( $self, $other ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $union = tie my @union, 'Ruby::Collections::Array';
	foreach my $item ( @{$self} ) {
		if ( not $union->include($item) ) {
			push( @union, $item );
		}
	}
	foreach my $item ( @{$other} ) {
		if ( not $union->include($item) ) {
			push( @union, $item );
		}
	}

	return $union;
}

if ( __FILE__ eq $0 ) {
	my $ref = [ 1, 2, 3, 4, 5, 11 ];
	p ra($ref)->map( sub { $_[0] * 2 } )->minmax;
}

1;
__END__;
