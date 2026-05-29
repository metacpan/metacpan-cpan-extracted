package Zuzu::Value::Equality;

use utf8;

our $VERSION = '0.001000';

use Exporter qw(import);

our @EXPORT_OK = qw(
	equality_type
	value_equal
	stable_value_key
);

use B qw(
	SVf_IOK
	SVf_NOK
	SVf_POK
	svref_2object
);
use Scalar::Util qw(
	blessed
	refaddr
);

sub _scalar_type {
	my ( $value ) = @_;
	my $flags = svref_2object( \$value )->FLAGS;
	my $is_numeric = ( $flags & ( SVf_IOK | SVf_NOK ) ) ? 1 : 0;
	my $is_stringy = ( $flags & SVf_POK ) ? 1 : 0;

	return 'Number' if $is_numeric and ! $is_stringy;
	return 'String' if ! $is_numeric and $is_stringy;

	if ( $is_numeric and $is_stringy ) {
		return ( $value =~ /\A-?(?:\d+(?:\.\d+)?)\z/ ) ? 'Number' : 'String';
	}

	return 'String';
}

sub equality_type {
	my ( $value ) = @_;

	return 'Null' if ! defined $value;
	if ( blessed($value) and $value->isa('Zuzu::Value::Boolean') ) {
		return 'Boolean';
	}
	if ( ref $value ) {
		return ref $value;
	}

	return _scalar_type( $value );
}

sub stable_value_key {
	my ( $value ) = @_;
	my $type = equality_type( $value );
	my %encoders = (
		Null => sub { return 'Null:null'; },
		Boolean => sub { return 'Boolean:' . ( $value->value ? '1' : '0' ); },
		Number => sub { return 'Number:' . ( 0 + $value ); },
		String => sub { return 'String:' . $value; },
	);

	if ( exists $encoders{$type} ) {
		return $encoders{$type}->();
	}

	if ( blessed($value) and $value->can('_stable_key') ) {
		return $type . ':' . $value->_stable_key;
	}

	return $type . ':' . ( refaddr( $value ) // "$value" );
}

sub value_equal {
	my ( $left, $right ) = @_;
	my $left_type = equality_type( $left );
	my $right_type = equality_type( $right );

	return 0 if $left_type ne $right_type;

	my %comparators = (
		Null => sub { return 1; },
		Boolean => sub { return $left->value == $right->value ? 1 : 0; },
		Number => sub { return ( 0 + $left ) == ( 0 + $right ) ? 1 : 0; },
		String => sub { return $left eq $right ? 1 : 0; },
	);

	if ( exists $comparators{$left_type} ) {
		return $comparators{$left_type}->();
	}

	if ( blessed($left) and blessed($right) ) {
		return 0 if ref($left) ne ref($right);

		if ( $left->isa('Zuzu::Value::Array') ) {
			return _array_equal( $left, $right );
		}
		if ( $left->isa('Zuzu::Value::Bag') ) {
			return _bag_equal( $left, $right );
		}
		if ( $left->isa('Zuzu::Value::Set') ) {
			return _set_equal( $left, $right );
		}
		if ( $left->isa('Zuzu::Value::Dict') ) {
			return _dict_equal( $left, $right );
		}
		if ( $left->isa('Zuzu::Value::PairList') ) {
			return _pairlist_equal( $left, $right );
		}
	}

	return stable_value_key( $left ) eq stable_value_key( $right ) ? 1 : 0;
}

sub _array_equal {
	my ( $left, $right ) = @_;

	my $left_items = $left->items // [];
	my $right_items = $right->items // [];

	return 0 if @$left_items != @$right_items;

	for my $i ( 0 .. $#$left_items ) {
		return 0 if !value_equal(
			$left->_value_at($i),
			$right->_value_at($i),
		);
	}

	return 1;
}

sub _bag_equal {
	my ( $left, $right ) = @_;

	my @left_items = sort {
		stable_value_key( $a ) cmp stable_value_key( $b )
	} $left->resolved_items;
	my @right_items = sort {
		stable_value_key( $a ) cmp stable_value_key( $b )
	} $right->resolved_items;

	return 0 if @left_items != @right_items;

	for my $i ( 0 .. $#left_items ) {
		return 0 if !value_equal( $left_items[$i], $right_items[$i] );
	}

	return 1;
}

sub _set_equal {
	my ( $left, $right ) = @_;

	for my $left_item ( $left->resolved_items ) {
		return 0 if !$right->contains( $left_item );
	}
	for my $right_item ( $right->resolved_items ) {
		return 0 if !$left->contains( $right_item );
	}

	return 1;
}

sub _dict_equal {
	my ( $left, $right ) = @_;

	my @left_keys = sort CORE::keys %{ $left->map // {} };
	my @right_keys = sort CORE::keys %{ $right->map // {} };

	return 0 if @left_keys != @right_keys;

	for my $i ( 0 .. $#left_keys ) {
		return 0 if !value_equal( $left_keys[$i], $right_keys[$i] );
	}
	for my $key ( @left_keys ) {
		return 0 if !value_equal(
			$left->_value_for_key($key),
			$right->_value_for_key($key),
		);
	}

	return 1;
}

sub _pairlist_equal {
	my ( $left, $right ) = @_;

	my $left_pairs = $left->list // [];
	my $right_pairs = $right->list // [];

	return 0 if @$left_pairs != @$right_pairs;

	for my $i ( 0 .. $#$left_pairs ) {
		my $left_pair = $left_pairs->[$i] // [];
		my $right_pair = $right_pairs->[$i] // [];

		return 0 if !value_equal( $left_pair->[0], $right_pair->[0] );
		return 0 if !value_equal(
			$left->_value_at($i),
			$right->_value_at($i),
		);
	}

	return 1;
}

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Value::Equality >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
