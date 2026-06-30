package Zuzu::Value::Dict;

use utf8;

our $VERSION = '0.007001';

use Moo;

use Zuzu::Value::Array;
use Zuzu::Value::Bag;
use Zuzu::Value::Set;
use Scalar::Util qw( blessed );
use Zuzu::Weak qw( slot_value store_value );

has 'map' => ( is => 'rw', default => sub { {} } );
has 'weak' => ( is => 'rw', default => sub { {} } );

sub _normalize_key {
	my ( $key ) = @_;

	return defined $key ? "$key" : '';
}

sub _store_key {
	my ( $self, $key, $value, $weak ) = @_;

	$key = _normalize_key($key);
	$self->weak->{$key} = $weak ? 1 : 0;
	store_value( \$self->map->{$key}, $value, $weak );

	return $self;
}

sub _value_for_key {
	my ( $self, $key ) = @_;

	$key = _normalize_key($key);

	return slot_value( \$self->map->{$key} );
}

sub copy {
	my ( $self ) = @_;
	my $copy = Zuzu::Value::Dict->new( map => {} );

	for my $key ( CORE::keys %{ $self->map } ) {
		$copy->_store_key(
			$key,
			$self->_value_for_key($key),
			$self->weak->{$key} ? 1 : 0,
		);
	}

	return $copy;
}

sub keys {
	my ( $self ) = @_;

	my $set = Zuzu::Value::Set->new( items => [] );
	$set->add( CORE::keys %{ $self->map } );

	return $set;
}

sub values {
	my ( $self ) = @_;

	my @values = map {
		$self->_value_for_key($_)
	} sort CORE::keys %{ $self->map };

	return Zuzu::Value::Bag->new( items => \@values );
}

sub enumerate {
	my ( $self ) = @_;

	my @pairs = map {
		[ $_, $self->_value_for_key($_) ]
	} sort CORE::keys %{ $self->map };

	return Zuzu::Value::Bag->new( items => \@pairs );
}


sub contains_key {
	my ( $self, $key ) = @_;
	my $map = $self->map;

	$key = _normalize_key($key);

	return exists $map->{ $key } ? 1 : 0;
}

sub contains {
	my ( $self, $key ) = @_;

	return $self->contains_key($key);
}

sub exists {
	my ( $self, $key ) = @_;

	return $self->contains_key($key);
}

sub defined {
	my ( $self, $key ) = @_;
	my $map = $self->map;

	$key = _normalize_key($key);

	return 0 if ! exists $map->{ $key };

	return defined $self->_value_for_key($key) ? 1 : 0;
}

sub get {
	my ( $self, $key, $default ) = @_;
	my $map = $self->map;

	$key = _normalize_key($key);

	return $self->_value_for_key($key) if exists $map->{ $key };

	return $default;
}

sub to_Array {
	my ( $self ) = @_;
	my @pairs = map {
		[ $_, $self->_value_for_key($_) ]
	} sort CORE::keys %{ $self->map };

	return Zuzu::Value::Array->new( items => \@pairs );
}

sub to_Iterator {
	my ( $self ) = @_;

	my @keys = sort CORE::keys %{ $self->map };
	my $index = 0;

	return sub {
		die 'ExhaustedException' if $index >= @keys;
		my $value = $keys[$index];
		$index++;

		return $value;
	};
}

sub add {
	my ( $self, @args ) = @_;

	if ( @args == 2 ) {
		my ( $k, $v ) = @args;
		$self->_store_key( $k, $v, 0 );

		return $self;
	}
	for my $pair ( @args ) {
		if ( ref($pair) eq 'ARRAY' and @$pair >= 2 ) {
			my ( $k, $v ) = @$pair;
			$self->_store_key( $k, $v, 0 );
			next;
		}
		if ( blessed($pair) and $pair->can('key') and $pair->can('value') ) {
			$self->_store_key( $pair->key, $pair->value, 0 );
			next;
		}
	}

	return $self;
}

sub set {
	my ( $self, $key, $value ) = @_;

	return $self->_store_key( $key, $value, 0 );
}

sub add_weak {
	my ( $self, $key, $value ) = @_;

	return $self->_store_key( $key, $value, 1 );
}

sub set_weak {
	my ( $self, $key, $value ) = @_;

	return $self->_store_key( $key, $value, 1 );
}

sub remove {
	my ( $self, $k_or_cb ) = @_;

	if ( ref($k_or_cb) eq 'CODE' ) {
		my @keys = CORE::keys %{ $self->map };
		for my $k ( @keys ) {
			my $pair = [ $k, $self->_value_for_key($k) ];
			if ( $k_or_cb->($pair) ) {
				delete $self->map->{ $k };
				delete $self->weak->{ $k };
			}
		}

		return $self;
	}
	if ( ref($k_or_cb) eq 'ARRAY' and @$k_or_cb ) {
		$k_or_cb = $k_or_cb->[0];
	}
	elsif ( ref($k_or_cb) and blessed($k_or_cb) and $k_or_cb->can('key') ) {
		$k_or_cb = $k_or_cb->key;
	}

	$k_or_cb = _normalize_key($k_or_cb);
	delete $self->map->{ $k_or_cb };
	delete $self->weak->{ $k_or_cb };

	return $self;
}

sub for_each_pair {
	my ( $self, $callback ) = @_;

	for my $k ( sort CORE::keys %{ $self->map } ) {
		$callback->( [ $k, $self->_value_for_key($k) ] );
	}

	return $self;
}

sub for_each_key {
	my ( $self, $callback ) = @_;

	for my $k ( sort CORE::keys %{ $self->map } ) {
		$callback->($k);
	}

	return $self;
}

sub for_each_value {
	my ( $self, $callback ) = @_;

	for my $k ( sort CORE::keys %{ $self->map } ) {
		$callback->( $self->_value_for_key($k) );
	}

	return $self;
}

sub kv {
	my ( $self ) = @_;
	my @out;
	for my $k ( sort CORE::keys %{ $self->map } ) {
		push @out, $k, $self->_value_for_key($k);
	}

	return Zuzu::Value::Array->new( items => \@out );
}

sub sorted_keys {
	my ( $self ) = @_;
	my @keys = sort CORE::keys %{ $self->map };

	return Zuzu::Value::Array->new( items => \@keys );
}

sub length { scalar CORE::keys %{ $_[0]->map } }

sub empty { scalar CORE::keys %{ $_[0]->map } ? 0 : 1 }

sub count { $_[0]->length }

sub is_empty { $_[0]->empty }

sub clear {
	my ( $self ) = @_;
	$self->map( {} );
	$self->weak( {} );

	return $self;
}

sub is_truthy { scalar(CORE::keys %{$_[0]->map}) ? 1 : 0 }

=pod

=head1 NAME

Zuzu::Value::Dict - runtime value class for dict values

=head1 DESCRIPTION

Wraps runtime dictionary/hash values and provides truthiness semantics for collections.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

None.

=head1 ATTRIBUTES

=head2 map

Type: B<HashRef>.

Dictionary storage map from keys to runtime values.

=head1 METHODS

=head2 new

Constructs and returns a new instance of this class.

=head2 is_truthy

Returns this runtime value's truthiness in ZuzuScript.

=head2 keys

Returns dictionary keys as a set.

=head2 values

Returns dictionary values as a bag.

=head2 contains_key

Returns true when the provided key exists.

=head2 get

Returns the value for a key or an optional default value.

=head2 to_Array

Returns an array of C<[ key, value ]> pairs.

=head2 add

Adds one or more key-value pairs and returns this dictionary.

=head2 remove

Deletes one key and returns this dictionary.

=head2 length

Returns the number of keys.

=head2 empty

Returns true when the dictionary has no keys.

=head2 clear

Removes all keys and returns this dictionary.

=head1 SEE ALSO

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Value::Dict >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
