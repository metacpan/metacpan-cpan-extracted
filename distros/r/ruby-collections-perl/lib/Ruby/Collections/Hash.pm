package Ruby::Collections::Hash;
use Tie::Hash;
our @ISA = 'Tie::StdHash';
use strict;
use v5.10;
use Scalar::Util qw(reftype);
use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Ruby::Collections::OrderedHash;
use Ruby::Collections;
use overload (
	'==' => \&eql,
	'eq' => \&eql,
	'!=' => \&not_eql,
	'ne' => \&not_eql,
	'""' => \&to_s
);

sub TIEHASH {
	my $class = shift;

	my $hash = tie my %hash, 'Ruby::Collections::OrderedHash';

	bless \%hash, $class;
}

=item has_all()
  Return 1.
  If block is given, return 1 if all results are true,
  otherwise 0.
  
  rh()->has_all                                  # return 1
  rh(1, 2, 3)->has_all                           # return 1
  rh(2, 4, 6)->has_all( sub { $_[0] % 2 == 1 } ) # return 0
=cut

sub has_all {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		while ( my ( $key, $val ) = each %$self ) {
			return 0 if ( not $block->( $key, $val ) );
		}
	}

	return 1;
}

=item has_any()
  Check if any entry exists.
  When block given, check if any result returned by block are true.
  
  rh( 1 => 2 )->has_any # return 1
  rh->has_any           # return 0
  rh ( 2 => 4, 6 => 8 )->has_any( sub { $_[0] % 2 == 1 } ) # return 0
=cut

sub has_any {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		while ( my ( $key, $val ) = each %$self ) {
			return 1 if ( $block->( $key, $val ) );
		}
		return 0;
	}
	else {
		return $self->size > 0 ? 1 : 0;
	}
}

=item assoc()
  Find the key and return the key-value pair in a Ruby::Collections::Array.
  Return undef if key is not found.
  
  rh( 'a' => 123, 'b' => 456 )->assoc('b') # return [ 'b', 456 ]
  rh( 'a' => 123, 'b' => 456 )->assoc('c') # return undef
=cut

sub assoc {
	my ( $self, $obj ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( $self->{$obj} ) {
		return ra( $obj, $self->{$obj} );
	}
	else {
		return undef;
	}
}

=item chunk()
  Chunk consecutive elements which is under certain condition
  into [ condition, [ [ key, value ]... ] ] array.
  
  rh( 1 => 1, 2 => 2, 3 => 3, 5 => 5, 4 => 4 )->chunk( sub { $_[0] % 2 } )
  #return  [ [ 1, [ [ 1, 1 ] ] ],
             [ 0, [ [ 2, 2 ] ] ],
             [ 1, [ [ 3, 3 ], [ 5, 5 ] ] ],
             [ 0, [ [ 4, 4 ] ] ] ]
=cut

sub chunk {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	my $prev    = undef;
	my $chunk   = tie my @chunk, 'Ruby::Collections::Array';
	my $i       = 0;

	while ( my ( $k, $v ) = each %$self ) {
		my $key = $block->( $k, $v );
		if ( p_obj($key) eq p_obj($prev) ) {
			$chunk->push( ra( $k, $v ) );
		}
		else {
			if ( $i != 0 ) {
				my $sub_ary = tie my @sub_ary, 'Ruby::Collections::Array';
				$sub_ary->push( $prev, $chunk );
				$new_ary->push($sub_ary);
			}
			$prev = $key;
			$chunk = tie my @chunk, 'Ruby::Collections::Array';
			$chunk->push( ra( $k, $v ) );
		}
		$i++;
	}
	if ( $chunk->has_any ) {
		my $sub_ary = tie my @sub_ary, 'Ruby::Collections::Array';
		$sub_ary->push( $prev, $chunk );
		$new_ary->push($sub_ary);
	}

	return $new_ary;
}

=item claer()
  Clear all keys and values.
=cut

sub clear {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	%$self = ();

	return $self;
}

=item delete()
  Delete the kry-value pair by key, return the value after deletion.
  If block is given, passing the value after deletion
  and return the result of block.
  
  rh( 'a' => 1 )->delete('a')                     # return 1
  rh( 'a' => 1 )->delete('b')                     # return undef
  rh( 'a' => 1 )->delete( 'a', sub{ $_[0] * 3 } ) # return 3
=cut

sub delete {
	my ( $self, $key, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		return $block->( delete $self->{$key} );
	}
	else {
		return delete $self->{$key};
	}
}

=item count()
  Count the number of key-value pairs.
  If block is given, count the number of results returned by
  the block which are true.
  
  rh( 'a' => 'b', 'c' => 'd' )->count # return 2
  rh( 1 => 3, 2 => 4, 5 => 6 )->count( sub {
  	  my ( $key, $val ) = @_;
  	  $key % 2 == 0 && $val % 2 == 0;
  } )
  # return 1
=cut

sub count {
	my ( $self, $ary_or_block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $count = 0;
	if ( defined $ary_or_block ) {
		if ( ref($ary_or_block) eq 'CODE' ) {
			while ( my ( $key, $val ) = each %$self ) {
				if ( $ary_or_block->( $key, $val ) ) {
					$count++;
				}
			}
		}
		elsif ( reftype($ary_or_block) eq 'ARRAY' ) {
			while ( my ( $key, $val ) = each %$self ) {
				if (   p_obj( @{$ary_or_block}[0] ) eq p_obj($key)
					&& p_obj( @{$ary_or_block}[1] ) eq p_obj($val) )
				{
					$count++;
				}
			}
		}
	}
	else {
		return $self->length;
	}

	return $count;
}

=item cycle()
  Apply the block with each key-value pair repeatedly.
  If a limit is given, it only repeats limit of cycles.
  
  rh( 1 => 2, 3 => 4 )->cycle( sub { print "$_[0], $_[1], " } )
  # print 1, 2, 3, 4, 1, 2, 3, 4... forever
  
  rh( 1 => 2, 3 => 4 )->cycle( 1, sub { print "$_[0], $_[1], " } )
  # print 1, 2, 3, 4, 
=cut

sub cycle {
	my $self = shift @_;
	ref($self) eq __PACKAGE__ or die;

	if ( @_ == 1 ) {
		my ($block) = @_;
		while (1) {
			while ( my ( $key, $val ) = each %$self ) {
				$block->( $key, $val );
			}
		}
	}
	elsif ( @_ == 2 ) {
		my ( $n, $block ) = @_;
		for ( my $i = 0 ; $i < $n ; $i++ ) {
			while ( my ( $key, $val ) = each %$self ) {
				$block->( $key, $val );
			}
		}
	}
	else {
		die 'ArgumentError: wrong number of arguments ('
		  . scalar(@_)
		  . ' for 0..1)';
	}
}

=item delete_if()
  Pass all key-value pairs into the block and remove them out of self
  if the results returned by the block are true.
  
  rh( 1 => 3, 2 => 4 )->delete_if( sub {
  	  my ( $key, $val ) = @_;
  	  $key % 2 == 1;
  } )
  # return { 2 => 4 }
=cut

sub delete_if {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	while ( my ( $key, $val ) = each %$self ) {
		if ( $block->( $key, $val ) ) {
			delete $self->{$key};
		}
	}

	return $self;
}

=item drop()
  Remove the first n key-value pair and store rest of elements
  in a new Ruby::Collections::Array.
  
  rh( 1 => 2, 3 => 4, 5 => 6)->drop(1) # return [ [ 3, 4 ], [ 5, 6 ] ]
=cut

sub drop {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	die 'ArgumentError: attempt to drop negative size' if ( $n < 0 );

	my $new_ary = ra;
	my $index   = 0;
	while ( my ( $key, $val ) = each %$self ) {
		if ( $n <= $index ) {
			$new_ary->push( ra( $key, $val ) );
		}
		$index++;
	}

	return $new_ary;
}

=item drop_while()
  Remove the first n key-value pair until the result returned by
  the block is true and store rest of elements in a new Ruby::Collections::Array.
  
  rh( 0 => 2, 1 => 3, 2 => 4, 5 => 7)->drop_while( sub {
  	  my ( $key, $val ) = @_;
  	  $key % 2 == 1;
  } )
  # return [ [ 1, 3 ], [ 2, 4 ], [ 5, 7 ] ]
=cut

sub drop_while {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary   = ra;
	my $cut_point = 0;
	while ( my ( $key, $val ) = each %$self ) {
		if ( $block->( $key, $val ) || $cut_point ) {
			$cut_point = 1;
			$new_ary->push( ra( $key, $val ) );
		}
	}

	return $new_ary;
}

=item each()
  Iterate each key-value pair and pass it to the block
  one by one. Return self.
  Alias: each_entry(), each_pair()
  
  rh( 1 => 2, 3 => 4)->each( sub {
      my ( $key, $val ) = @_;
      print "$key, $val, "
  } )
  # print 1, 2, 3, 4, 
=cut

sub each {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	while ( my ( $key, $val ) = each %$self ) {
		$block->( $key, $val );
	}

	return $self;
}

*each_entry = \&each;

*each_pair = \&each;

=item each_cons()
  Iterates each key-value pair([ k, v ]) as array of consecutive <n> elements.
  
  rh( 1 => 2, 3 => 4, 5 => 6 )->each_cons( 2, sub{
  	  my ($sub_ary) = @_;
  	  p $sub_ary[0]->zip($sub_ary[1]);
  } )
  # print "[[1, 3], [2, 4]]\n[[3, 5], [4, 6]]\n"
=cut

sub each_cons {
	my ( $self, $n, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a->each_cons( $n, $block );
}

=item each_slice()
  Put each key and value into a Ruby::Collections::Array and chunk them
  into other Ruby::Collections::Array(s) of size n.
  
  rh( 1 => 2, 3 => 4, 5 => 6 )->each_slice(2)
  # return [ [ [ 1, 2 ], [ 3, 4] ], [ [ 5, 6 ] ] ]
=cut

sub each_slice {
	my ( $self, $n, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a->each_slice( $n, $block );
}

=item each_key()
  Put each key in to a Ruby::Collections::Array.
  
  rh( 1 => 2, 'a' => 'b', [ 3, { 'c' => 'd' } ] => 4 ).each_key( sub {
  	  print "$_[0], "
  } )
  # print "1, a, [3, {c=>d}], "
=cut

sub each_key {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	for my $key ( keys %$self ) {
		$block->($key);
	}

	return $self;
}

=item each_value()
  Put each value in to a Ruby::Collections::Array.
  
  rh( 1 => 2, 'a' => undef, '3' => rh( [2] => [3] ) )->each_value( sub {
      print "$_[0], "
  } )
  # print "2, undef, {[2]=>[3]}, "
=cut

sub each_value {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	for my $val ( values %$self ) {
		$block->($val);
	}

	return $self;
}

=item each_with_index()
  Iterate each key-value pair and pass it with index to the block
  one by one. Return self.
  
  rh( 'a' => 'b', 'c' => 'd' )->each_with_index( sub {
      my ( $key, $val, $index ) = @_;
      print "$key, $val, $index, "
  } )
  # print "a, b, 0, c, d, 1, " 
=cut

sub each_with_index {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		my $index = 0;
		while ( my ( $key, $val ) = each %$self ) {
			$block->( $key, $val, $index );
			$index++;
		}
	}

	return $self;
}

=item each_with_object()
  Iterate each key-value pair and pass it with an object to the block
  one by one. Return the object.
  
  my $ra = ra;
  rh( 1 => 2, 3 => 4 )->each_with_object( $ra, sub {
      my ( $key, $val, $obj ) = @_;
      $obj->push( $key, $val );
  } );
  p $ra;
  # print "[1, 2, 3, 4]\n" 
=cut

sub each_with_object {
	my ( $self, $object, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		while ( my ( $key, $val ) = each %$self ) {
			$block->( $key, $val, $object );
		}
	}

	return $object;
}

=item is_empty()
  Check if Ruby::Collections::Hash is empty or not.
  
  rh()->is_empty         # return 1
  rh( 1 => 2 )->is_empty # return 0
=cut

sub is_empty {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	return scalar( keys %$self ) == 0 ? 1 : 0;
}

=item entries()
  Put each key-value pair to a Ruby::Collections::Array.
  
  rh( 1 => 2, 3 => 4)->entries # return [ [ 1, 2 ], [ 3, 4 ] ]
=cut

sub entries {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a;
}

=item eql
  Check if contents of both hashes are the same. Key order is not matter.
  
  rh( 1 => 2, 3 => 4 )->eql( { 3 => 4, 1 => 2 } )       # return 1
  rh( [1] => 2, 3 => 4 )->eql( { 3 => 4, [1] => 2 } )   # return 0
  rh( [1] => 2, 3 => 4 )->eql( rh( 3 => 4, [1] => 2 ) ) # return 1
=cut

sub eql {
	my ( $self, $other ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( reftype($other) eq 'HASH' ) {
		while ( my ( $key, $val ) = each %$self ) {
			if ( p_obj($val) ne p_obj( $other->{$key} ) ) {
				return 0;
			}
		}
	}
	else {
		return 0;
	}

	return 1;
}

sub not_eql {
	my ( $self, $other ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->eql($other) == 0 ? 1 : 0;
}

=item fetch()
  Retrieve the value by certain key. Throw an exception if key is not found.
  If default value is given, return the default value when key is not found.
  If block is given, pass the key into the block and return the result when
  key is not found.
  
  rh( 1 => 2, 3 => 4 )->fetch(1)                          # return 2
  rh( 1 => 2, 3 => 4 )->fetch( 5, 10 )                    # return 10
  rh( 1 => 2, 3 => 4 )->fetch( 5, sub { $_[0] * $_[0] } ) # return 25
=cut

sub fetch {
	my ( $self, $key, $default_or_block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $val = $self->{$key};
	if ( defined $val ) {
		return $val;
	}
	else {
		if ( defined $default_or_block ) {
			if ( ref($default_or_block) eq 'CODE' ) {
				return $default_or_block->($key);
			}
			else {
				return $default_or_block;
			}
		}
		else {
			die 'KeyError: key not found: ' . $key;
		}
	}
}

=item find()
  Find the first key-value pair which result returned by
  the block is true. If default is given, return the default
  when such pair can't be found.
  Alias: detect()
  
  rh( 'a' => 1, 'b' => 2 )->find( sub {
      my ( $key, $val ) = @_;
      $val % 2 == 0;
  } )
  # return [ 'b', 2 ]
  
  rh( 'a' => 1, 'b' => 2 )->detect( sub { 'Not Found!' }, sub {
      my ( $key, $val ) = @_;
      $val % 2 == 3;
  } )
  # return 'Not Found!'
=cut

sub find {
	my $self = shift @_;
	ref($self) eq __PACKAGE__ or die;

	if ( @_ == 1 ) {
		my ($block) = @_;
		while ( my ( $key, $val ) = each %$self ) {
			if ( $block->( $key, $val ) ) {
				return ra( $key, $val );
			}
		}
	}
	elsif ( @_ == 2 ) {
		my ( $default, $block ) = @_;
		while ( my ( $key, $val ) = each %$self ) {
			if ( $block->( $key, $val ) ) {
				return ra( $key, $val );
			}
		}
		return $default->();
	}
	else {
		die 'ArgumentError: wrong number of arguments ('
		  . scalar(@_)
		  . ' for 0..1)';
	}

	return undef;
}

*detect = \&find;

=item find_all()
  Pass each key-value pair to the block and store all elements
  which are true returned by the block to a Ruby::Collections::Array.
  
  rh( 'a' => 'b', 1 => 2, 'c' => 'd', 3 => '4')->select(
      sub {
          my ( $key, $val ) = @_;
          looks_like_number($key) && looks_like_number($val);
      }
  )
  # return [ [ 1, 2 ], [ 3, 4 ] ]
=cut

sub find_all {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = ra;
	while ( my ( $key, $val ) = each %$self ) {
		if ( $block->( $key, $val ) ) {
			$new_ary->push( ra( $key, $val ) );
		}
	}

	return $new_ary;
}

=item find_index()
  Find the position of pair under certain condition. Condition can be
  an array which contains the target key & value or can be a block.
  
  rh( 1 => 2, 3 => 4 )->find_index( [ 5, 6 ] )           # return undef
  rh( 1 => 2, 3 => 4 )->find_index( [ 3, 4 ] )           # return 1
  rh( 1 => 2, 3 => 4 )->find_index( sub { $_[0] == 1 } ) # return 0
=cut

sub find_index {
	my ( $self, $ary_or_block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( reftype($ary_or_block) eq 'ARRAY' ) {
		my $index = 0;
		while ( my ( $key, $val ) = each %$self ) {
			if (   p_obj( @{$ary_or_block}[0] ) eq p_obj($key)
				&& p_obj( @{$ary_or_block}[1] ) eq p_obj($val) )
			{
				return $index;
			}
			$index++;
		}
	}
	elsif ( ref($ary_or_block) eq 'CODE' ) {
		my $index = 0;
		while ( my ( $key, $val ) = each %$self ) {
			if ( $ary_or_block->( $key, $val ) ) {
				return $index;
			}
			$index++;
		}
	}

	return undef;
}

=item first()
  Return the first element. If n is specified, return the first n elements.
  
  rh( 1 => 2, 3 => 4)->first    # return [ [ 1, 2 ] ]
  rh( 1 => 2, 3 => 4)->first(5) # return [ [ 1, 2 ], [ 3, 4 ] ]
=cut

sub first {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $n ) {
		die 'ArgumentError: negative array size' if ( $n < 0 );

		my $new_ary = ra;
		while ( my ( $key, $val ) = each %$self ) {
			if ( $n <= 0 ) {
				return $new_ary;
			}
			$new_ary->push( ra( $key, $val ) );
			$n--;
		}
		return $new_ary;
	}
	else {
		while ( my ( $key, $val ) = each %$self ) {
			return ra( $key, $val );
		}
		return undef;
	}
}

=item flat_map()
  Call map(), then call flatten(1).
  Alias: collect_concat()
  
  rh( 1 => 2, 3 => 4 )->flat_map(
      sub {
          my ( $key, $val ) = @_;
          [ $key * $val ];
      }
  )
  # return [ 2, 12 ]
=cut

sub flat_map {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = $self->map($block);
	$new_ary->flattenEx(1);

	return $new_ary;
}

*collect_concat = \&flat_map;

=item flatten()
  Push each key & value into a Ruby::Collections::Array. If n is specified,
  call flatten( n - 1 ) on the Ruby::Collections::Array.
  
  rh( 1 => [ 2, 3 ], 4 => 5 )->flatten    # return [ 1, [ 2, 3 ], 4, 5 ]
  rh( 1 => [ 2, 3 ], 4 => 5 )->flatten(2) # return [ 1, 2, 3, 4, 5 ]
=cut

sub flatten {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = ra();
	while ( my ( $key, $val ) = each %$self ) {
		$new_ary->push( $key, $val );
	}

	if ( defined $n && $n >= 2 ) {
		$new_ary->flattenEx( $n - 1 );
	}

	return $new_ary;
}

=item grep()
  Using regex to match elements and store them in a Ruby::Collecitons::Array.
  If block is given, transform each element by the block.
  Note: This implementation is different from Ruby due to the missing of ===
  operator in Perl.
  
  rh( 'a' => 1, '2' => 'b', 'c' => 3 )->grep(qr/^\[[a-z]/) # return [[a, 1], [c, 3]]
  rh( 'a' => 1, '2' => 'b', 'c' => 3 )->grep( qr/^\[[a-z]/, sub {
  	  $_[0] << 'z';
  })
  # return [[a, 1, z], [c, 3, z]]
=cut

sub grep {
	my ( $self, $pattern, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a->grep( $pattern, $block );
}

=item group_by()
  Group each element by the result of block, store them in a Ruby::Collections::Hash.
  
  rh( 1 => 3, 0 => 4, 2 => 5 )->group_by(sub {
  	  $_[0] + $_[1]
  })
  #return
=cut

sub group_by {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_hash = rh;
	while ( my ( $key, $val ) = each %$self ) {
		my $group = $block->( $key, $val );
		if ( defined $new_hash->{$group} ) {
			$new_hash->{$group}->push( ra( $key, $val ) );
		}
		else {
			$new_hash->{$group} = ra;
			$new_hash->{$group}->push( ra( $key, $val ) );
		}
	}

	return $new_hash;
}

=item include()
  Check if key exists.
  Alias: has_key(), has_member()
  
  rh( 1 => 2, [ 3, { 4 => 5 } ] => 5, undef => 6 )->include(1)                 # return 1
  rh( 1 => 2, [ 3, { 4 => 5 } ] => 6, undef => 7 )->has_key([ 3, { 4 => 5 } ]) # return 1
  rh( 1 => 2, [ 3, { 4 => 5 } ] => 5, undef => 6 )->has_member(undef)          # return 1
  rh( 1 => 2, [ 3, { 4 => 5 } ] => 5, undef => 6 )->include(7)                 # return 0
=cut

sub include {
	my ( $self, $key ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return ra( keys %$self )->include($key);
}

*has_key = \&include;

*has_member = \&include;

=item inject()
  Passing the result of block by each iteration to next iteration, return the
  final result in the end.
  Alias: reduce()
  
  rh( 1 => 2, 3 => 4, 5 => 6 )->inject( sub {
  	  my ( $o, $i ) = @_;
  	  @$o[0] += @$i[0];
  	  @$o[1] += @$i[1];
  	  $o;
  })
  # return [ 9, 12 ]
  rh( 1 => 2, 3 => 4, 5 => 6 )->inject( [ 7, 7 ], sub {
      my ( $o, $i ) = @_;
      @$o[0] += @$i[0];
      @$o[1] += @$i[1];
      $o;
  })
  # return [ 16, 19 ]
=cut

sub inject {
	my $self = shift @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a->inject(@_);
}

*reduce = \&inject;

=item inspect()
  Return the data structure in string form of self.
  Alias: to_s()
  
  rh( [ 1, 2 ] => 3, 'a' => 'b' )->inspect # return { [ 1, 2 ] => 3, a => b }
=cut

sub inspect {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	return p_hash $self;
}

*to_s = \&inspect;

=item
  Invert the whole hash. Let values be the keys and keys be the values.
  
  rh( 1 => 'a', 2 => 'b', 3 => 'a' )->invert # return { a => 3, b => 2 }
=cut

sub invert {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_hash = rh;
	while ( my ( $key, $val ) = each %$self ) {
		$new_hash->{$val} = $key;
	}

	return $new_hash;
}

=item keep_if()
  Pass all key-value pairs to the block and only keep the elements which get the results
  returned by the block are true.
  
  rh( 1 => 1, 2 => 2, 3 => 3 )->keep_if( sub { $_[0] % 2 == 1 } ) # return { 1 => 1, 3 => 3 }
=cut

sub keep_if {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	while ( my ( $key, $val ) = each %$self ) {
		if ( not $block->( $key, $val ) ) {
			delete $self->{$key};
		}
	}

	return $self;
}

=item key()
  Find the key by value.
  
  rh( 1 => 2, 3 => 2 )->key(2) # return 1
  rh( 1 => 2, 3 => 2 )->key(4) # return undef
=cut

sub key {
	my ( $self, $value ) = @_;
	ref($self) eq __PACKAGE__ or die;

	while ( my ( $key, $val ) = each %$self ) {
		if ( p_obj($value) eq p_obj($val) ) {
			return $key;
		}
	}

	return undef;
}

=item keys()
  Put all keys in a Ruby::Collections::Array.
  
  rh( 1 => 2, 3 => 4, 5 => 6 )->keys # return [ 1, 3, 5 ]
=cut

sub keys {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	return ra( keys %$self );
}

=item length()
  Return the number of key-value pairs.
  Alias: size()
  
  rh->length                # return 0
  rh( 1 => 2, 3 => 4)->size # return 2
=cut

sub length {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	return scalar( keys %$self );
}

*size = \&length;

=item map()
  Transform each key-value pair and store them into a new Ruby::Collections::Array.
  Alias: collect()
  
  rh( 1 => 2, 3 => 4 )->map(
      sub {
          my ( $key, $val ) = @_;
          $key * $val;
      }
  )
  # return [ 2, 12 ]
=cut

sub map {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = ra;
	while ( my ( $key, $val ) = each %$self ) {
		$new_ary->push( $block->( $key, $val ) );
	}

	return $new_ary;
}

*collect = \&map;

=item max()
  Find the max element of a Ruby::Collections::Hash.
  transform each element to scalar then compare it.
  
  rh( 6 => 5, 11 => 3, 2 => 1 )->max                                        # return [ 6, 5 ]
  rh( 6 => 5, 11 => 3, 2 => 1 )->max( sub { @{$_[0]}[0] <=> @{$_[1]}[0] } ) # return [ 11, 3 ]
=cut

sub max {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a->max($block);
}

=item max_by()
  Transform all elements by the given block and then find the max.
  Return the element which is the origin of the max.
  
  rh( 6 => 5, 11 => 3, 2 => 20 )->max_by( sub { @{$_[0]}[0] + @{$_[0]}[1] } ) # return [ 2, 20 ]
=cut

sub max_by {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a->max_by($block);
}

=item merge()
  Merge all key-value pairs of other hash with self elements into a
  new Ruby::Collections::Hash.
  
  rh( 1 => 2, 3 => 4 )->merge( { 3 => 3, 4 => 5 } ) # return { 1 => 2, 3 => 3, 4 => 5 }
=cut

sub merge {
	my ( $self, $other_hash, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_hash = rh($self);
	while ( my ( $key, $val ) = each %$other_hash ) {
		if ( defined $block && $self->{$key} && $other_hash->{$key} ) {
			$new_hash->{$key} =
			  $block->( $key, $self->{$key}, $other_hash->{$key} );
		}
		else {
			$new_hash->{$key} = $val;
		}
	}

	return $new_hash;
}

*update = \&merge;

=item mergeEx()
  Merge all key-value pairs of other hash with self elements and save result into self.
  
  rh( 1 => 2, 3 => 4 )->mergeEx( { 3 => 3, 4 => 5 } ) # return { 1 => 2, 3 => 3, 4 => 5 }
=cut

sub mergeEx {
	my ( $self, $other_hash, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	while ( my ( $key, $val ) = each %$other_hash ) {
		if ( defined $block && $self->{$key} && $other_hash->{$key} ) {
			$self->{$key} =
			  $block->( $key, $self->{$key}, $other_hash->{$key} );
		}
		else {
			$self->{$key} = $val;
		}
	}

	return $self;
}

*updateEx = \&mergeEx;

=item min()
  Find the min element of a Ruby::Collections::Hash. If block is not given,
  transform each element to scalar then compare it.
  
  rh( 6 => 5, 11 => 3, 2 => 1 )->min # return [ 11, 3 ]
  rh( 6 => 5, 11 => 3, 2 => 1 )->min( sub {
  	  @{$_[0]}[1] - @{$_[0]}[0] <=> @{$_[1]}[1] - @{$_[1]}[0]
  })
  # return [ 11, 3 ]
=cut

sub min {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a->min($block);
}

=item min_by()
  Transform all elements by the given block and then find the max.
  Return the element which is the origin of the max.
  
  rh( 6 => 5, 11 => 3, 2 => 20 )->min_by( sub { @{$_[0]}[0] + @{$_[0]}[1] } ) # return [ 6, 5 ]
=cut

sub min_by {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a->min_by($block);
}

=item minmax()
  Find the min & max elements of a Ruby::Collections::Hash. If block is not given,
  transform each element to scalar then compare it.
  
  rh( 1 => 10, 2 => 9, 3 => 8 )->minmax # return [ [ 1, 10 ], [ 3, 8] ]
  rh( 1 => 10, 2 => 9, 3 => 8 )->minmax( sub {
      @{$_[0]}[1] - @{$_[0]}[0] <=> @{$_[1]}[1] - @{$_[1]}[0]
  })
  # return [ [ 3, 8 ], [ 1, 10 ] ]
=cut

sub minmax {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a->minmax($block);
}

=item minmax_by()
  Transform all elements by the given block and then find the min & max.
  Return the element which is the origin of the min & max.
  
  rh( 6 => 5, 11 => 3, 2 => 20 )->minmax_by( sub { @{$_[0]}[0] * @{$_[0]}[1] } )
  # return [ [ 6, 5 ], [ 2, 20 ] ]
=cut

sub minmax_by {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a->minmax_by($block);
}

=item has_none()
  If hash is empty, return 1, otherwise 0. If block is given and all results of block
  are false, return 1, otherwise 0.
  
  rh->has_none                                                   # return 1
  rh( 1 => 2 )->has_none                                         # return 0
  rh( 'a' => 'b' )->has_none( sub {
  	  my ( $key, $val ) = @_;
  	  looks_like_number($key);
  })
  # return 1
=cut

sub has_none {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $block ) {
		while ( my ( $key, $val ) = each %$self ) {
			return 0 if ( $block->( $key, $val ) );
		}
	}
	else {
		while ( my ( $key, $val ) = each %$self ) {
			return 0;
		}
	}

	return 1;
}

=item has_one()
  If hash has one element, return 1, otherwise 0. If block is given and one result of block
  are true, return 1, otherwise 0.
  
  rh->has_one                                                           # return 0
  rh( 1 => 2 )->has_one                                                 # return 1
  rh( 'a' => 'b', 1 => 2 )->has_one( sub {
  	  my ( $key, $val ) = @_;
      looks_like_number($key);
  })
  # return 1
=cut

sub has_one {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $count = 0;
	if ( defined $block ) {
		while ( my ( $key, $val ) = each %$self ) {
			if ( $block->( $key, $val ) ) {
				$count++;
				return 0 if ( $count > 1 );
			}
		}
	}
	else {
		while ( my ( $key, $val ) = each %$self ) {
			$count++;
			return 0 if ( $count > 1 );
		}
	}

	return $count == 1 ? 1 : 0;
}

=item partition()
  Separate elements into 2 groups by given block.
  
  rh( 'a' => 1, 2 => 'b', 'c' => 3, 4 => 'd' )->partition( sub{
  	  my ( $key, $val ) = @_;
  	  looks_like_number($key);
  })
=cut

sub partition {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary   = ra;
	my $true_ary  = ra;
	my $false_ary = ra;
	while ( my ( $key, $val ) = each %$self ) {
		if ( $block->( $key, $val ) ) {
			$true_ary->push( ra( $key, $val ) );
		}
		else {
			$false_ary->push( ra( $key, $val ) );
		}
	}
	$new_ary->push( $true_ary, $false_ary );

	return $new_ary;
}

=item rassoc()
  Find the value and return the key-value pair in a Ruby::Collections::Array.
  Return undef if value is not found.
  
  rh( 'a' => 123, 'b' => 123 )->rassoc(123) # return [ 'a', 123 ]
  rh( 'a' => 123, 'b' => 123 )->rassoc(456) # return undef
=cut

sub rassoc {
	my ( $self, $obj ) = @_;
	ref($self) eq __PACKAGE__ or die;

	while ( my ( $key, $val ) = each %$self ) {
		if ( $obj eq $val ) {
			return ra( $key, $val );
		}
	}

	return undef;
}

=item reject()
  Pass all key-value pairs into the block and store them into a Ruby::Collecitons::Array
  if the results returned by the block are false.
  
  rh( 1 => 3, 2 => 4, 5 => 6 )->reject( sub {
      my ( $key, $val ) = @_;
      $key % 2 == 1;
  } )
  # return { 2 => 4, 5 => 6 }
=cut

sub reject {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_hash = rh($self);
	while ( my ( $key, $val ) = each %$new_hash ) {
		if ( $block->( $key, $val ) ) {
			delete $new_hash->{$key};
		}
	}

	return $new_hash;
}

=item rejectEx()
  Pass all key-value pairs into the block and remove them out of self
  if the results returned by the block are true. Return undef if nothing is deleted.
  
  rh( 1 => 3, 2 => 4 )->rejectEx( sub {
      my ( $key, $val ) = @_;
      $key % 2 == 1;
  } )
  # return { 2 => 4 }
  rh( 1 => 3, 2 => 4 )->rejectEx( sub {
      my ( $key, $val ) = @_;
      $key == 5;
  } )
  # return undef
=cut

sub rejectEx {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $before_len = $self->size;
	$self->delete_if($block);

	if ( $self->size == $before_len ) {
		return undef;
	}
	else {
		return $self;
	}
}

=item reverse_each()
  Iterate key-value pair backward to a block.
  
  rh( 1 => 2, 3 => 4, 5 => 6 )->reverse_each( sub {
  	  my ( $key, $val ) = @_;
  	  print "$key, $val, ";
  } )
  # print "5, 6, 3, 4, 1, 2, "
=cut

sub reverse_each {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = $self->to_a->reverseEx;
	if ( defined $block ) {
		for my $item ( @{$new_ary} ) {
			$block->( @{$item}[0], @{$item}[1] );
		}
	}

	return $new_ary;
}

=item replace()
  Replace all elements with other hash.
  
  rh( 1 => 2 )->replace( { 3 => 4, 5 => 6 } ) # return { 3 => 4, 5 => 6 } 
=cut

sub replace {
	my ( $self, $other_hash ) = @_;
	ref($self) eq __PACKAGE__ or die;

	%$self = %$other_hash;

	return $self;
}

=item select()
  Pass each key-value pair to the block and remain all elements
  which are true returned by the block in self. Return undef if
  nothing changed.
  
  rh( 'a' => 'b', 1 => 2, 'c' => 'd', 3 => '4')->select(
      sub {
          my ( $key, $val ) = @_;
          looks_like_number($key) && looks_like_number($val);
      }
  )
  # return { 1 => 2, 3 => 4 }
=cut

sub select {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_hash = rh;
	while ( my ( $key, $val ) = each %$self ) {
		if ( $block->( $key, $val ) ) {
			$new_hash->{$key} = $val;
		}
	}

	return $new_hash;
}

=item selectEx()
  Pass each key-value pair to the block and remain all elements
  which are true returned by the block in self. Return undef if
  nothing changed.
  
  rh( 'a' => 'b', 1 => 2, 'c' => 'd', 3 => '4')->selectEx(
      sub {
          my ( $key, $val ) = @_;
          looks_like_number($key) && looks_like_number($val);
      }
  )
  # return { 1 => 2, 3 => 4 }
  rh( 'a' => 'b', 1 => 2, 'c' => 'd', 3 => '4')->selectEx(
      sub {
          my ( $key, $val ) = @_;
          $key == 5;
      }
  )
  # return undef
=cut

sub selectEx {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_hash = rh;
	while ( my ( $key, $val ) = each %$self ) {
		if ( $block->( $key, $val ) ) {
			$new_hash->{$key} = $val;
		}
	}

	if ( $new_hash->size == $self->size ) {
		return undef;
	}
	else {
		%$self = %$new_hash;
		return $self;
	}
}

=item shift()
  Shift the first key-value pair out of self.
  
  rh( 1 => 2 )->shift # return [ 1, 2 ]
  rh->shift           # undef
=cut

sub shift {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	while ( my ( $key, $val ) = each %$self ) {
		my $new_ary = ra( $key, $val );
		delete $self->{$key};
		return $new_ary;
	}

	return undef;
}

=item slice_before()
  Separate elements into groups, the first element of each group is
  defined by block or regex.
  
  rh( 'a' => 1, 'b' => 0, 'c' => 0, 'd' => 1 )->slice_before( sub {
  	  my ( $key, $val ) = @_;
  	  $val == 0;
  } )
  # return [ [ [ a, 1 ] ], [ [ b, 0 ] ], [ [ c, 0 ], [ d, 1 ] ] ]
  rh( 'a' => 1, 'b' => 0, 'c' => 0, 'd' => 1 )->slice_before(qr/^\[[a-z]/)
  # return [ [ [ a, 1 ] ], [ [ b, 0 ] ], [ [ c, 0 ] ], [ [ d, 1 ] ] ]
=cut

sub slice_before {
	my $self = shift @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = tie my @new_ary, 'Ruby::Collections::Array';
	my $group = undef;
	if ( ref( @_[0] ) eq 'CODE' ) {
		my $block = shift @_;

		while ( my ( $key, $val ) = each %$self ) {
			if ( not defined $group ) {
				$group = tie my @group, 'Ruby::Collections::Array';
				push( @group, ra( $key, $val ) );
			}
			elsif ( $block->( $key, $val ) ) {
				push( @new_ary, $group );
				$group = tie my @group, 'Ruby::Collections::Array';
				push( @group, ra( $key, $val ) );
			}
			else {
				push( @{$group}, ra( $key, $val ) );
			}
		}
	}
	else {
		my $pattern = shift @_;

		while ( my ( $key, $val ) = each %$self ) {
			if ( not defined $group ) {
				$group = tie my @group, 'Ruby::Collections::Array';
				push( @group, ra( $key, $val ) );
			}
			elsif ( ra( $key, $val )->to_s =~ $pattern ) {
				push( @new_ary, $group );
				$group = tie my @group, 'Ruby::Collections::Array';
				push( @group, ra( $key, $val ) );
			}
			else {
				push( @{$group}, ra( $key, $val ) );
			}
		}
	}
	if ( defined $group && $group->has_any ) {
		push( @new_ary, $group );
	}

	return $new_ary;
}

=item store()
  Store a key-value pair.
  
  rh( 1 => 2 )->store( 3, 4 ) # return 4
=cut

sub store {
	my ( $self, $key, $val ) = @_;
	ref($self) eq __PACKAGE__ or die;

	$self->{$key} = $val;

	return $val;
}

=item take()
  Take first n elements and put them into a Ruby::Collections::Array.
  
  rh( 1 => 2, 3 => 4, 5 => 6 )->take(2) # return [ [ 1, 2 ], [ 3, 4 ] ]
=cut

sub take {
	my ( $self, $n ) = @_;
	ref($self) eq __PACKAGE__ or die;

	if ( defined $n ) {
		die 'ArgumentError: negative array size' if ( $n < 0 );

		my $new_ary = ra;
		while ( my ( $key, $val ) = each %$self ) {
			if ( $n <= 0 ) {
				return $new_ary;
			}
			$new_ary->push( ra( $key, $val ) );
			$n--;
		}
		return $new_ary;
	}
	else {
		die 'ArgumentError: wrong number of arguments (0 for 1)';
	}
}

=item take_while()
  Start to take elements while result returned by block is true and
  put them into a Ruby::Collections::Array.
  
  rh( 1 => 2, 3 => 4, 5 => 6 )->take_while( sub {
  	  my ( $key, $val ) = @_;
  	  $key <= 3;
  } )
  # return [ [ 1, 2 ], [ 3, 4 ] ]
=cut

sub take_while {
	my ( $self, $block ) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_ary = ra;
	while ( my ( $key, $val ) = each %$self ) {
		if ( $block->( $key, $val ) ) {
			$new_ary->push( ra( $key, $val ) );
		}
		else {
			return $new_ary;
		}
	}

	return $new_ary;
}

=item to_a()
  Converts self to a nested array of [ key, value ] Ruby::Collections::Array.
  
  rh( 1 => 2, 'a' => 'b' )->to_a # return [ [ 1, 2 ], [ a, b ] ]
=cut

sub to_a {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_array = ra();
	while ( my ( $key, $val ) = each %$self ) {
		$new_array->push( ra( $key, $val ) );
	}

	return $new_array;
}

=item to_h()
  Return self;
  Alias: to_hash()
=cut

sub to_h {
	my ($self) = @_;
	ref($self) eq __PACKAGE__ or die;

	return $self;
}

*to_hash = \&to_h;

=item has_value()
  Retuen 1 if a value exists, otherwise 0.
  
  rh( 1 => 2, 3 => 4 )->has_value(4) # return 1
  rh( 1 => 2, 3 => 4 )->has_value(5) # return 0
=cut

sub has_value {
	my ( $self, $val ) = @_;
	ref($self) eq __PACKAGE__ or die;

	return ra( values %$self )->include($val);
}

=item values_at()
  Put all values corresponding to the input keys into a Ruby::Collections::Array.
  
  rh( 1 => 2, 3 => 4, 5 => 6 )->values_at( 3, 4, 6 ) # return [ 4, undef, undef ]
=cut

sub values_at {
	my $self = shift @_;
	ref($self) eq __PACKAGE__ or die;

	my $new_array = ra();
	for my $key (@_) {
		$new_array->push( $self->{$key} );
	}

	return $new_array;
}

=item zip()
  Call to_a first, then zip an array of elements into self.
  
  rh( 1 => [ 2, 3 ], 4 => [ 5, 6 ], 7 => 8 )->zip( [ 9, 10 ] )
  # return [ [ [ 1, [ 2, 3 ] ], 9 ], [ [ 4, [ 5, 6 ] ], 10 ], [ [ 7, 8 ], undef ] ]
=cut

sub zip {
	my $self = shift @_;
	ref($self) eq __PACKAGE__ or die;

	return $self->to_a->zip(@_);
}

if ( __FILE__ eq $0 ) {
	rh( 1 => 2, 3 => 4 )->each_entry( sub{
		my ( $k, $v ) = @_;
	} );
}

1;
__END__;
