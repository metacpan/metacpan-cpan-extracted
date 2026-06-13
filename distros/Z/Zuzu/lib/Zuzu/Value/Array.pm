package Zuzu::Value::Array;

use utf8;

our $VERSION = '0.004000';

use Moo;

use Zuzu::Value::Bag;
use Zuzu::Value::Set;
use Zuzu::Value::Equality qw( value_equal );
use Zuzu::Weak qw( slot_value store_value );
use List::Util qw( sum0 );

has 'items' => ( is => 'rw', default => sub { [] } );
has 'weak' => ( is => 'rw', default => sub { [] } );

sub _store_at {
	my ( $self, $index, $value, $weak ) = @_;

	$self->weak->[$index] = $weak ? 1 : 0;
	store_value( \$self->items->[$index], $value, $weak );

	return $value;
}

sub _value_at {
	my ( $self, $index ) = @_;

	return slot_value( \$self->items->[$index] );
}

sub resolved_items {
	my ( $self ) = @_;

	my @out;
	for ( my $i = 0; $i < @{ $self->items }; $i++ ) {
		push @out, $self->_value_at($i);
	}

	return @out;
}

sub push {
	my ( $self, @vals ) = @_;

	for my $value ( @vals ) {
		my $index = scalar @{ $self->items };
		$self->_store_at( $index, $value, 0 );
	}

	return $self;
}

sub push_weak {
	my ( $self, @vals ) = @_;

	for my $value ( @vals ) {
		my $index = scalar @{ $self->items };
		$self->_store_at( $index, $value, 1 );
	}

	return $self;
}

sub pop {
	my ( $self ) = @_;

	pop @{ $self->weak };

	return pop @{ $self->items };
}

sub unshift {
	my ( $self, @vals ) = @_;

	CORE::unshift @{ $self->items }, (undef) x @vals;
	CORE::unshift @{ $self->weak }, (0) x @vals;
	for my $i ( 0 .. $#vals ) {
		$self->_store_at( $i, $vals[$i], 0 );
	}

	return $self;
}

sub unshift_weak {
	my ( $self, @vals ) = @_;

	CORE::unshift @{ $self->items }, (undef) x @vals;
	CORE::unshift @{ $self->weak }, (1) x @vals;
	for my $i ( 0 .. $#vals ) {
		$self->_store_at( $i, $vals[$i], 1 );
	}

	return $self;
}

sub shift {
	my ( $self ) = @_;

	shift @{ $self->weak };

	return shift @{ $self->items };
}

sub clear {
	my ( $self ) = @_;
	$self->items( [] );
	$self->weak( [] );

	return $self;
}

sub copy {
	my ( $self ) = @_;
	my $copy = Zuzu::Value::Array->new( items => [] );

	for ( my $i = 0; $i < @{ $self->items }; $i++ ) {
		$copy->_store_at(
			$i,
			$self->_value_at($i),
			$self->weak->[$i] ? 1 : 0,
		);
	}

	return $copy;
}

sub get {
	my ( $self, $index, $default ) = @_;
	$index = 0 + ( $index // 0 );

	return $self->_value_at($index)
		if $index >= 0 and $index < @{ $self->items };

	return $default;
}

sub set {
	my ( $self, $index, $value ) = @_;
	$index = 0 + ( $index // 0 );
	$self->_store_at( $index, $value, 0 );

	return $self;
}

sub set_weak {
	my ( $self, $index, $value ) = @_;
	$index = 0 + ( $index // 0 );
	$self->_store_at( $index, $value, 1 );

	return $self;
}

sub map {
	my ( $self, $mapper ) = @_;
	my @out = map { $mapper->($_) } $self->resolved_items;

	return Zuzu::Value::Array->new( items => \@out );
}

sub grep {
	my ( $self, $pred ) = @_;
	my @out = grep { $pred->($_) } $self->resolved_items;

	return Zuzu::Value::Array->new( items => \@out );
}

sub any {
	my ( $self, $pred ) = @_;
	for my $v ( $self->resolved_items ) {
		return 1 if $pred->($v);
	}

	return 0;
}

sub all {
	my ( $self, $pred ) = @_;
	for my $v ( $self->resolved_items ) {
		return 0 if !$pred->($v);
	}

	return 1;
}

sub first {
	my ( $self, $pred ) = @_;
	for my $v ( $self->resolved_items ) {
		return $v if $pred->($v);
	}

	return undef;
}

sub remove {
	my ( $self, $pred ) = @_;
	my @items;
	my @weak;
	for ( my $i = 0 ; $i < @{ $self->items } ; $i++ ) {
		my $value = $self->_value_at($i);
		next if $pred->($value);
		CORE::push @items, undef;
		CORE::push @weak, $self->weak->[$i] ? 1 : 0;
		store_value( \$items[-1], $value, $weak[-1] );
	}
	$self->items( \@items );
	$self->weak( \@weak );

	return $self;
}

sub first_index {
	my ( $self, $pred ) = @_;

	for ( my $i = 0 ; $i < @{ $self->items } ; $i++ ) {
		return $i if $pred->( $self->_value_at($i) );
	}

	return -1;
}

sub reduce {
	my ( $self, $reducer ) = @_;
	return undef if ! @{ $self->items };

	my $acc = $self->_value_at(0);
	for ( my $i = 1 ; $i < @{ $self->items } ; $i++ ) {
		$acc = $reducer->( $acc, $self->_value_at($i) );
	}

	return $acc;
}

sub reductions {
	my ( $self, $reducer ) = @_;
	return Zuzu::Value::Array->new( items => [] ) if ! @{ $self->items };

	my @out;
	my $acc = $self->_value_at(0);
	CORE::push @out, $acc;
	for ( my $i = 1 ; $i < @{ $self->items } ; $i++ ) {
		$acc = $reducer->( $acc, $self->_value_at($i) );
		CORE::push @out, $acc;
	}

	return Zuzu::Value::Array->new( items => \@out );
}

sub sum {
	my ( $self ) = @_;
	my @nums = map { 0 + ( $_ // 0 ) } $self->resolved_items;

	return sum0 @nums;
}

sub product {
	my ( $self ) = @_;
	my @nums = map { 0 + ( $_ // 0 ) } $self->resolved_items;

	return List::Util::product @nums;
}

sub head {
	my ( $self, $n ) = @_;
	$n = 1 if !defined $n;
	$n = 0 + $n;
	$n = 0 if $n < 0;

	my @out = $self->resolved_items;
	$#out = $n - 1 if @out > $n;

	return Zuzu::Value::Array->new( items => \@out );
}

sub tail {
	my ( $self, $n ) = @_;
	$n = 1 if !defined $n;
	$n = 0 + $n;
	$n = 0 if $n < 0;

	my @out = $self->resolved_items;
	@out = () if $n == 0;
	@out = @out[ @out - $n .. $#out ] if @out and $n > 0 and @out > $n;

	return Zuzu::Value::Array->new( items => \@out );
}

sub shuffle {
	my ( $self ) = @_;
	my @out = $self->resolved_items;
	for ( my $i = @out - 1 ; $i > 0 ; $i-- ) {
		my $j = int rand( $i + 1 );
		@out[ $i, $j ] = @out[ $j, $i ];
	}

	return Zuzu::Value::Array->new( items => \@out );
}

sub sample {
	my ( $self, $n ) = @_;
	$n = 1 if !defined $n;
	$n = 0 + $n;
	$n = 0 if $n < 0;

	my $shuffled = $self->shuffle;
	return $shuffled->head($n);
}

sub for_each_value {
	my ( $self, $callback ) = @_;

	for my $v ( $self->resolved_items ) {
		$callback->($v);
	}

	return $self;
}

sub to_Iterator {
	my ( $self ) = @_;

	my @items = $self->resolved_items;
	my $index = 0;

	return sub {
		die 'ExhaustedException' if $index >= @items;
		my $value = $items[$index];
		$index++;

		return $value;
	};
}

sub sort {
	my ( $self, $cmp ) = @_;
	my @out = CORE::sort { $cmp->( $a, $b ) } $self->resolved_items;

	return Zuzu::Value::Array->new( items => \@out );
}

sub sortstr {
	my ( $self ) = @_;
	my @out = CORE::sort {
		( defined $a ? "$a" : '' ) cmp ( defined $b ? "$b" : '' )
	} $self->resolved_items;

	return Zuzu::Value::Array->new( items => \@out );
}

sub sortnum {
	my ( $self ) = @_;
	my @out = CORE::sort {
		( 0 + ( $a // 0 ) ) <=> ( 0 + ( $b // 0 ) )
	} $self->resolved_items;

	return Zuzu::Value::Array->new( items => \@out );
}

sub reverse {
	my ( $self ) = @_;
	my @out = CORE::reverse $self->resolved_items;

	return Zuzu::Value::Array->new( items => \@out );
}


sub contains {
	my ( $self, $needle ) = @_;

	for my $item ( $self->resolved_items ) {
		return 1 if value_equal( $item, $needle );
	}

	return 0;
}

sub to_Set {
	my ( $self ) = @_;
	my $set = Zuzu::Value::Set->new( items => [] );
	$set->add( $self->resolved_items );

	return $set;
}

sub to_Bag {
	my ( $self ) = @_;

	return Zuzu::Value::Bag->new( items => [ $self->resolved_items ] );
}

sub length { scalar @{ $_[0]->items } }

sub empty { @{ $_[0]->items } ? 0 : 1 }

sub count { $_[0]->length }

sub is_empty { $_[0]->empty }

sub is_truthy { @{$_[0]->items} ? 1 : 0 }

=pod

=head1 NAME

Zuzu::Value::Array - runtime value class for array values

=head1 DESCRIPTION

Wraps runtime array values and provides truthiness semantics for collections.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

None.

=head1 ATTRIBUTES

=head2 items

Type: B<ArrayRef>.

Ordered array elements (expressions or runtime values).

=head1 METHODS

=head2 new

Constructs and returns a new instance of this class.

=head2 is_truthy

Returns this runtime value's truthiness in ZuzuScript.

=head2 push

Appends one or more items and returns this array.

=head2 pop

Removes and returns the final item.

=head2 unshift

Prepends one or more items and returns this array.

=head2 shift

Removes and returns the first item.

=head2 clear

Removes all items and returns this array.

=head2 length

Returns the number of items.

=head2 map

Returns a new array by mapping each element through a callback.

=head2 grep

Returns a new array with elements where callback is true.

=head2 any

Returns true if any element satisfies the callback.

=head2 all

Returns true if all elements satisfy the callback.

=head2 first

Returns the first matching element or undef when none match.

=head2 remove

Removes elements where callback returns true.

=head2 contains

Returns true when the array contains a matching value.

=head2 to_Set

Returns a new set with type-aware unique values from this array.

=head2 to_Bag

Returns a new bag containing this array's values.

=head2 empty

Returns true when the array has no items.

=head1 SEE ALSO

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Value::Array >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
