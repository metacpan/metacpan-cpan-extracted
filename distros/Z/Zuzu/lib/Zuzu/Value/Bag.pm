package Zuzu::Value::Bag;

use utf8;

our $VERSION = '0.001005';

use Moo;

use Zuzu::Value::Array;
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

sub copy {
	my ( $self ) = @_;
	my $copy = Zuzu::Value::Bag->new( items => [] );

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

	return $self;
}

sub add_weak {
	my ( $self, @vals ) = @_;

	for my $value ( @vals ) {
		my $index = scalar @{ $self->items };
		$self->_store_at( $index, $value, 1 );
	}

	return $self;
}

sub remove {
	my ( $self, $needle ) = @_;
	my @out;
	my @weak;
	my $removed = 0;
	for ( my $i = 0; $i < @{ $self->items }; $i++ ) {
		my $v = $self->_value_at($i);
		if ( ! $removed and value_equal( $v, $needle ) ) {
			$removed = 1;
			next;
		}
		push @out, undef;
		push @weak, $self->weak->[$i] ? 1 : 0;
		store_value( \$out[-1], $v, $weak[-1] );
	}
	$self->items( \@out );
	$self->weak( \@weak );

	return $self;
}

sub remove_first {
	my ( $self, $needle ) = @_;

	return $self->remove( $needle );
}


sub contains {
	my ( $self, $needle ) = @_;

	for my $item ( $self->resolved_items ) {
		return 1 if value_equal( $item, $needle );
	}

	return 0;
}

sub to_Array {
	my ( $self ) = @_;

	return Zuzu::Value::Array->new( items => [ $self->resolved_items ] );
}

sub to_Set {
	my ( $self ) = @_;
	my $set = Zuzu::Value::Set->new( items => [] );
	$set->add( $self->resolved_items );

	return $set;
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

	return Zuzu::Value::Bag->new( items => \@out );
}

sub grep {
	my ( $self, $pred ) = @_;
	my @out = grep { $pred->($_) } $self->resolved_items;

	return Zuzu::Value::Bag->new( items => \@out );
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

sub count {
	my ( $self, $needle ) = @_;

	return scalar @{ $self->items } if @_ < 2;

	my $count = 0;
	for my $v ( $self->resolved_items ) {
		$count++ if value_equal( $v, $needle );
	}

	return $count;
}

sub uniq {
	my ( $self ) = @_;
	my $set = Zuzu::Value::Set->new( items => [] );
	$set->add( $self->resolved_items );

	return $set;
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

sub for_each_value {
	my ( $self, $callback ) = @_;

	for my $v ( $self->resolved_items ) {
		$callback->($v);
	}

	return $self;
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

sub clear {
	$_[0]->items( [] );
	$_[0]->weak( [] );

	return $_[0];
}

sub is_truthy { @{$_[0]->items} ? 1 : 0 }

=pod

=head1 NAME

Zuzu::Value::Bag - runtime value class for bag values

=head1 DESCRIPTION

Wraps runtime bag values that keep duplicates without ordering guarantees.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

None.

=head1 ATTRIBUTES

=head2 items

Type: B<ArrayRef>.

Bag members, including duplicate entries.

=head1 METHODS

=head2 add

Adds one or more members.

=head2 remove

Removes a single matching member, if present.

=head2 remove_first

Alias for C<remove>.

=head2 contains

Returns true when the bag contains a matching value.

=head2 to_Array

Returns this bag as an array value.

=head2 to_Set

Returns this bag as a set value.

=head2 map

Returns a new bag by mapping each member through a callback.

=head2 grep

Returns a new bag containing members where callback is true.

=head2 any

Returns true if any member satisfies the callback.

=head2 all

Returns true if all members satisfy the callback.

=head2 first

Returns the first matching member or undef when none match.

=head2 remove_if

Removes members where callback returns true.

=head2 length

Returns the current member count.

=head2 empty

Returns true when the bag has no members.

=head2 clear

Removes all members from the bag.

=head2 is_truthy

Returns this runtime value's truthiness in ZuzuScript.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Value::Bag >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
