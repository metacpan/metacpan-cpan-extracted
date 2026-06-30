package Zuzu::Value::PairList;

use utf8;

our $VERSION = '0.007001';

use Moo;

use Zuzu::Value::Array;
use Zuzu::Value::Bag;
use Scalar::Util qw( blessed );
use Zuzu::Weak qw( slot_value store_value );

has 'list' => ( is => 'rw', default => sub { [] } ); # [ [key, value], ... ]
has 'weak' => ( is => 'rw', default => sub { [] } );

sub _normalize_key {
	my ( $key ) = @_;

	return defined $key ? "$key" : '';
}

sub _store_at {
	my ( $self, $index, $key, $value, $weak ) = @_;

	$self->list->[$index] = [ _normalize_key($key), undef ];
	$self->weak->[$index] = $weak ? 1 : 0;
	store_value( \$self->list->[$index][1], $value, $weak );

	return $self;
}

sub _append {
	my ( $self, $key, $value, $weak ) = @_;

	my $index = scalar @{ $self->list };

	return $self->_store_at( $index, $key, $value, $weak );
}

sub _value_at {
	my ( $self, $index ) = @_;

	return slot_value( \$self->list->[$index][1] );
}

sub copy {
	my ( $self ) = @_;
	my $copy = Zuzu::Value::PairList->new( list => [] );

	for ( my $i = 0; $i < @{ $self->list }; $i++ ) {
		$copy->_append(
			$self->list->[$i][0],
			$self->_value_at($i),
			$self->weak->[$i] ? 1 : 0,
		);
	}

	return $copy;
}

sub keys {
	my ( $self ) = @_;
	my @keys = map { $_->[0] } @{ $self->list };

	return Zuzu::Value::Array->new( items => \@keys );
}

sub values {
	my ( $self ) = @_;
	my @values;
	for ( my $i = 0; $i < @{ $self->list }; $i++ ) {
		push @values, $self->_value_at($i);
	}

	return Zuzu::Value::Array->new( items => \@values );
}

sub enumerate {
	my ( $self ) = @_;
	my @pairs;
	for ( my $i = 0; $i < @{ $self->list }; $i++ ) {
		push @pairs, [ $self->list->[$i][0], $self->_value_at($i) ];
	}

	return Zuzu::Value::Bag->new( items => \@pairs );
}

sub contains_key {
	my ( $self, $key ) = @_;
	$key = _normalize_key( $key );
	for my $pair ( @{ $self->list } ) {
		return 1 if $pair->[0] eq $key;
	}

	return 0;
}

sub exists {
	my ( $self, $key ) = @_;

	return $self->contains_key( $key );
}

sub defined {
	my ( $self, $key ) = @_;
	$key = _normalize_key( $key );
	for ( my $i = 0; $i < @{ $self->list }; $i++ ) {
		next if $self->list->[$i][0] ne $key;
		return defined $self->_value_at($i) ? 1 : 0;
	}

	return 0;
}

sub get {
	my ( $self, $key, $default ) = @_;
	$key = _normalize_key( $key );
	for ( my $i = 0; $i < @{ $self->list }; $i++ ) {
		return $self->_value_at($i) if $self->list->[$i][0] eq $key;
	}

	return $default;
}

sub get_all {
	my ( $self, $key ) = @_;
	$key = _normalize_key( $key );
	my @values;
	for ( my $i = 0; $i < @{ $self->list }; $i++ ) {
		push @values, $self->_value_at($i)
			if $self->list->[$i][0] eq $key;
	}

	return Zuzu::Value::Array->new( items => \@values );
}

sub all {
	my ( $self, $key ) = @_;

	return $self->get_all( $key );
}

sub to_Array {
	my ( $self ) = @_;
	my @pairs;
	for ( my $i = 0; $i < @{ $self->list }; $i++ ) {
		push @pairs, [ $self->list->[$i][0], $self->_value_at($i) ];
	}

	return Zuzu::Value::Array->new( items => \@pairs );
}

sub to_Iterator {
	my ( $self ) = @_;

	my @keys = map { $_->[0] } @{ $self->list };
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
		my ( $key, $value ) = @args;
		$self->_append( $key, $value, 0 );

		return $self;
	}

	for my $pair ( @args ) {
		if ( ref($pair) eq 'ARRAY' and @{ $pair } >= 2 ) {
			$self->_append( $pair->[0], $pair->[1], 0 );
			next;
		}
		if ( blessed($pair) and $pair->can('key') and $pair->can('value') ) {
			$self->_append( $pair->key, $pair->value, 0 );
			next;
		}
	}

	return $self;
}

sub add_weak {
	my ( $self, $key, $value ) = @_;

	return $self->_append( $key, $value, 1 );
}

sub set {
	my ( $self, $key, $value ) = @_;

	return $self->add( $key, $value );
}

sub set_weak {
	my ( $self, $key, $value ) = @_;

	return $self->add_weak( $key, $value );
}

sub remove {
	my ( $self, $k_or_cb ) = @_;

	if ( ref($k_or_cb) eq 'CODE' ) {
		my @kept;
		my @weak;
		for ( my $i = 0; $i < @{ $self->list }; $i++ ) {
			my $pair = $self->list->[$i];
			my $value = $self->_value_at($i);
			if ( !$k_or_cb->( [ $pair->[0], $value ] ) ) {
				push @kept, [ $pair->[0], undef ];
				push @weak, $self->weak->[$i] ? 1 : 0;
				store_value( \$kept[-1][1], $value, $weak[-1] );
			}
		}
		$self->list( \@kept );
		$self->weak( \@weak );

		return $self;
	}

	if ( ref($k_or_cb) eq 'ARRAY' and @{ $k_or_cb } ) {
		$k_or_cb = $k_or_cb->[0];
	}
	elsif ( ref($k_or_cb) and blessed($k_or_cb) and $k_or_cb->can('key') ) {
		$k_or_cb = $k_or_cb->key;
	}
	my $key = _normalize_key( $k_or_cb );
	my @kept;
	my @weak;
	for ( my $i = 0; $i < @{ $self->list }; $i++ ) {
		my $pair = $self->list->[$i];
		next if $pair->[0] eq $key;
		my $value = $self->_value_at($i);
		push @kept, [ $pair->[0], undef ];
		push @weak, $self->weak->[$i] ? 1 : 0;
		store_value( \$kept[-1][1], $value, $weak[-1] );
	}
	$self->list( \@kept );
	$self->weak( \@weak );

	return $self;
}

sub for_each_pair {
	my ( $self, $callback ) = @_;
	for ( my $i = 0; $i < @{ $self->list }; $i++ ) {
		my $pair = $self->list->[$i];
		$callback->( [ $pair->[0], $self->_value_at($i) ] );
	}

	return $self;
}

sub for_each_key {
	my ( $self, $callback ) = @_;
	for my $pair ( @{ $self->list } ) {
		$callback->( $pair->[0] );
	}

	return $self;
}

sub for_each_value {
	my ( $self, $callback ) = @_;
	for ( my $i = 0; $i < @{ $self->list }; $i++ ) {
		$callback->( $self->_value_at($i) );
	}

	return $self;
}

sub kv {
	my ( $self ) = @_;
	my @out;
	for ( my $i = 0; $i < @{ $self->list }; $i++ ) {
		push @out, $self->list->[$i][0], $self->_value_at($i);
	}

	return Zuzu::Value::Array->new( items => \@out );
}

sub sorted_keys {
	my ( $self ) = @_;
	my @keys = map { $_->[0] } @{ $self->list };
	@keys = sort @keys;

	return Zuzu::Value::Array->new( items => \@keys );
}

sub length { scalar @{ $_[0]->list } }
sub count { $_[0]->length }
sub empty { $_[0]->length ? 0 : 1 }
sub is_empty { $_[0]->empty }

sub clear {
	my ( $self ) = @_;
	$self->list( [] );
	$self->weak( [] );

	return $self;
}

sub is_truthy { scalar @{ $_[0]->list } ? 1 : 0 }

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Value::PairList >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
