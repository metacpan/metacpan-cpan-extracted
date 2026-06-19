package Zuzu::Value::Set;

use utf8;

our $VERSION = '0.006000';

use Moo;

use Zuzu::Value::Array;
use Zuzu::Value::Bag;
use Zuzu::Value::Equality qw(
	stable_value_key
	value_equal
);
use Zuzu::Weak qw( slot_value store_value );

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

sub _stable_key {
	my ( $self, $v ) = @_;

	return stable_value_key( $v );
}

sub _uniq {
	my ( $self ) = @_;

	my %seen;
	my @out;
	my @weak;
	for ( my $i = 0; $i < @{ $self->items }; $i++ ) {
		my $v = $self->_value_at($i);
		my $k = $self->_stable_key($v);
		next if exists $seen{$k};
		$seen{$k} = 1;
		push @out, undef;
		push @weak, $self->weak->[$i] ? 1 : 0;
		store_value( \$out[-1], $v, $weak[-1] );
	}
	$self->items( \@out );
	$self->weak( \@weak );

	return $self;
}

sub copy {
	my ( $self ) = @_;
	my $copy = Zuzu::Value::Set->new( items => [] );

	for ( my $i = 0; $i < @{ $self->items }; $i++ ) {
		$copy->_store_at(
			$i,
			$self->_value_at($i),
			$self->weak->[$i] ? 1 : 0,
		);
	}

	return $copy;
}

sub add {
	my ( $self, @vals ) = @_;

	for my $value ( @vals ) {
		my $index = scalar @{ $self->items };
		$self->_store_at( $index, $value, 0 );
	}
	$self->_uniq;

	return $self;
}

sub add_weak {
	my ( $self, @vals ) = @_;

	for my $value ( @vals ) {
		my $index = scalar @{ $self->items };
		$self->_store_at( $index, $value, 1 );
	}
	$self->_uniq;

	return $self;
}

sub push_weak {
	my ( $self, @vals ) = @_;

	return $self->add_weak(@vals);
}

sub remove {
	my ( $self, $needle ) = @_;
	my $nkey = $self->_stable_key($needle);
	my @out;
	my @weak;
	for ( my $i = 0; $i < @{ $self->items }; $i++ ) {
		my $v = $self->_value_at($i);
		my $k = $self->_stable_key($v);
		next if $k eq $nkey;
		push @out, undef;
		push @weak, $self->weak->[$i] ? 1 : 0;
		store_value( \$out[-1], $v, $weak[-1] );
	}
	$self->items( \@out );
	$self->weak( \@weak );

	return $self;
}


sub contains {
	my ( $self, $needle ) = @_;

	for my $item ( $self->resolved_items ) {
		return 1 if value_equal( $item, $needle );
	}

	return 0;
}

sub to_Bag {
	my ( $self ) = @_;

	return Zuzu::Value::Bag->new( items => [ $self->resolved_items ] );
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

sub map {
	my ( $self, $mapper ) = @_;

	my @out = map { $mapper->($_) } $self->resolved_items;
	my $set = Zuzu::Value::Set->new( items => [] );
	$set->add( @out );

	return $set;
}

sub grep {
	my ( $self, $pred ) = @_;

	my @out = grep { $pred->($_) } $self->resolved_items;
	my $set = Zuzu::Value::Set->new( items => [] );
	$set->add( @out );

	return $set;
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

sub remove_if {
	my ( $self, $pred ) = @_;

	my @out;
	my @weak;
	for ( my $i = 0; $i < @{ $self->items }; $i++ ) {
		my $value = $self->_value_at($i);
		next if $pred->($value);
		push @out, undef;
		push @weak, $self->weak->[$i] ? 1 : 0;
		store_value( \$out[-1], $value, $weak[-1] );
	}
	$self->items( \@out );
	$self->weak( \@weak );

	return $self;
}

sub for_each_value {
	my ( $self, $callback ) = @_;

	for my $v ( $self->resolved_items ) {
		$callback->($v);
	}

	return $self;
}

sub is_subset {
	my ( $self, $other ) = @_;
	for my $v ( $self->resolved_items ) {
		return 0 if ! $other->contains($v);
	}

	return 1;
}

sub is_superset {
	my ( $self, $other ) = @_;

	return $other->is_subset($self);
}

sub is_disjoint {
	my ( $self, $other ) = @_;

	for my $v ( $self->resolved_items ) {
		return 0 if $other->contains($v);
	}

	return 1;
}

sub equals {
	my ( $self, $other ) = @_;

	return 0 if $self->length != $other->length;

	return $self->is_subset($other);
}

sub union {
	my ( $self, $other ) = @_;
	my $out = Zuzu::Value::Set->new( items => [ $self->resolved_items ] );
	$out->add( $other->resolved_items );

	return $out;
}

sub intersection {
	my ( $self, $other ) = @_;
	my @out = grep { $other->contains($_) } $self->resolved_items;
	my $set = Zuzu::Value::Set->new( items => [] );
	$set->add(@out);

	return $set;
}

sub difference {
	my ( $self, $other ) = @_;
	my @out = grep { ! $other->contains($_) } $self->resolved_items;
	my $set = Zuzu::Value::Set->new( items => [] );
	$set->add(@out);

	return $set;
}

sub symmetric_difference {
	my ( $self, $other ) = @_;
	my $left = $self->difference($other);
	my $right = $other->difference($self);

	return $left->union($right);
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

sub length { scalar @{ $_[0]->items } }

sub empty { @{ $_[0]->items } ? 0 : 1 }

sub count { $_[0]->length }

sub is_empty { $_[0]->empty }

sub clear {
	$_[0]->items( [] );
	$_[0]->weak( [] );

	return $_[0];
}

sub to_Array {
	my ( $self ) = @_;

	return Zuzu::Value::Array->new( items => [ $self->resolved_items ] );
}

sub is_truthy { @{$_[0]->items} ? 1 : 0 }

=pod

=head1 NAME

Zuzu::Value::Set - runtime value class for set values

=head1 DESCRIPTION

Wraps runtime set values and enforces uniqueness for added elements.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

None.

=head1 ATTRIBUTES

=head2 items

Type: B<ArrayRef>.

Unique set members stored in insertion order for predictable iteration.

=head1 METHODS

=head2 add

Adds one or more members and keeps only unique values.

=head2 remove

Removes all occurrences of the provided member.

=head2 contains

Returns true when the set contains a matching value.

=head2 to_Bag

Returns a bag containing this set's members.

=head2 map

Returns a new set by mapping each member through a callback.

=head2 grep

Returns a new set containing members where callback is true.

=head2 any

Returns true if any member satisfies the callback.

=head2 all

Returns true if all members satisfy the callback.

=head2 first

Returns the first matching member or undef when none match.

=head2 remove_if

Removes members where callback returns true.

=head2 length

Returns the current number of members.

=head2 empty

Returns true when the set has no members.

=head2 clear

Removes all members from the set.

=head2 to_Array

Returns this set as an array value.

=head2 is_truthy

Returns this runtime value's truthiness in ZuzuScript.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Value::Set >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
