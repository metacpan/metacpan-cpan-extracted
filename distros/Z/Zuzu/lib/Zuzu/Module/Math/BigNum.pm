package Zuzu::Module::Math::BigNum;

use utf8;

our $VERSION = '0.004000';

use Math::BigFloat;
use Math::BigInt;

use Zuzu::Util::NativeHelpers qw(
	native_class
	native_function
	native_object
);

sub _coerce_bignum {
	my ( $value ) = @_;

	if ( ref($value) and ref($value) eq 'Math::BigFloat' ) {
		return $value->copy;
	}
	if ( ref($value)
		and $value->isa('Zuzu::Value::Object')
		and $value->class->name eq 'BigNum'
	) {
		my $raw = $value->slots->{__value};
		return $raw->copy if ref($raw) and ref($raw) eq 'Math::BigFloat';
		return Math::BigFloat->new( defined $raw ? "$raw" : '0' );
	}

	return Math::BigFloat->new( defined $value ? "$value" : '0' );
}

sub _wrap {
	my ( $class_obj, $value ) = @_;

	return native_object(
		class => $class_obj,
		slots => {
			__value => _coerce_bignum( $value ),
		},
		const => {
			__value => 1,
		},
	);
}

sub _self_value {
	my ( $self ) = @_;
	return _coerce_bignum( $self->slots->{__value} );
}

sub _to_plain_decimal {
	my ( $value ) = @_;
	my $text = $value->bstr;

	if ( $text =~ /e/i ) {
		$text = $value->copy->bnormalize->bstr;
	}

	return $text;
}

sub _to_zuzu_string {
	my ( $value ) = @_;
	my $text = 's' . _to_plain_decimal( $value );
	substr( $text, 0, 1, '' );
	return $text;
}

sub IMPORT {
	my ( $class, $runtime ) = @_;

	my $bignum_class = native_class(
		name => 'BigNum',
	);

	$bignum_class->static_methods->{from_dec} = native_function(
		name => 'from_dec',
		native => sub {
			my ( $klass, $raw ) = @_;
			return _wrap( $klass, Math::BigFloat->new( defined $raw ? "$raw" : '0' ) );
		},
	);

	$bignum_class->static_methods->{from_hex} = native_function(
		name => 'from_hex',
		native => sub {
			my ( $klass, $raw ) = @_;
			my $text = defined $raw ? "$raw" : '0x0';
			return _wrap( $klass, Math::BigFloat->from_hex( $text ) );
		},
	);

	$bignum_class->methods->{is_int} = native_function(
		name => 'is_int',
		native => sub {
			my ( $self ) = @_;
			return _self_value( $self )->is_int ? 1 : 0;
		},
	);

	my @cmp_names = qw( bcmp beq bne blt ble bgt bge );
	for my $name ( @cmp_names ) {
		$bignum_class->methods->{$name} = native_function(
			name => $name,
			native => sub {
				my ( $self, $other ) = @_;
				my $cmp = _self_value( $self )->bcmp( _coerce_bignum( $other ) );
				return 0 + $cmp if $name eq 'bcmp';
				return $cmp == 0 ? 1 : 0 if $name eq 'beq';
				return $cmp != 0 ? 1 : 0 if $name eq 'bne';
				return $cmp < 0 ? 1 : 0 if $name eq 'blt';
				return $cmp <= 0 ? 1 : 0 if $name eq 'ble';
				return $cmp > 0 ? 1 : 0 if $name eq 'bgt';
				return $cmp >= 0 ? 1 : 0 if $name eq 'bge';
				return 0;
			},
		);
	}

	my %unary = (
		babs => sub { $_[0]->copy->babs },
		bneg => sub { $_[0]->copy->bneg },
		binv => sub {
			my ( $value ) = @_;
			return Math::BigFloat->new('0')
				if $value->is_zero;
			return Math::BigFloat->new('1')->bdiv( $value->copy, 128 );
		},
		bsin => sub { $_[0]->copy->bsin },
		bcos => sub { $_[0]->copy->bcos },
		btan => sub {
			my ( $value ) = @_;
			my $sin = $value->copy->bsin;
			my $cos = $value->copy->bcos;
			return Math::BigFloat->new('0')
				if $cos->is_zero;
			return $sin->bdiv($cos);
		},
		bsqrt => sub { $_[0]->copy->bsqrt },
		bround => sub {
			my ( $value ) = @_;
			my $n = $value->numify;
			my $rounded = $n >= 0 ? int( $n + 0.5 ) : int( $n - 0.5 );
			return Math::BigFloat->new("$rounded");
		},
		bfloor => sub { $_[0]->copy->bfloor },
		bceil => sub { $_[0]->copy->bceil },
	);
	for my $name ( sort keys %unary ) {
		$bignum_class->methods->{$name} = native_function(
			name => $name,
			native => sub {
				my ( $self ) = @_;
				return _wrap( $bignum_class, $unary{$name}->( _self_value( $self ) ) );
			},
		);
	}

	my %binary = (
		badd => sub { $_[0]->copy->badd( $_[1] ) },
		bsub => sub { $_[0]->copy->bsub( $_[1] ) },
		bmul => sub { $_[0]->copy->bmul( $_[1] ) },
		bdiv => sub { $_[0]->copy->bdiv( $_[1] ) },
		bmod => sub { $_[0]->copy->bmod( $_[1] ) },
		bpow => sub {
			my ( $lhs, $rhs ) = @_;
			return $lhs->as_int->copy->bpow( $rhs->as_int )
				if $lhs->is_int && $rhs->is_int && $rhs >= 0;
			return $lhs->copy->bpow( $rhs );
		},
	);
	for my $name ( sort keys %binary ) {
		$bignum_class->methods->{$name} = native_function(
			name => $name,
			native => sub {
				my ( $self, $other ) = @_;
				my $lhs = _self_value( $self );
				my $rhs = _coerce_bignum( $other );
				return _wrap( $bignum_class, $binary{$name}->( $lhs, $rhs ) );
			},
		);
	}

	$bignum_class->methods->{to_hex} = native_function(
		name => 'to_hex',
		native => sub {
			my ( $self ) = @_;
			my $value = _self_value( $self );
			my $int = $value->copy->as_int;
			my $text = $int->as_hex;
			$text =~ s/\A\+//;
			return $text;
		},
	);

	$bignum_class->methods->{to_dec} = native_function(
		name => 'to_dec',
		native => sub {
			my ( $self ) = @_;
			return _to_zuzu_string( _self_value( $self ) );
		},
	);

	$bignum_class->methods->{to_String} = native_function(
		name => 'to_String',
		native => sub {
			my ( $self ) = @_;
			return _to_zuzu_string( _self_value( $self ) );
		},
	);

	$bignum_class->methods->{to_Number} = native_function(
		name => 'to_Number',
		native => sub {
			my ( $self ) = @_;
			return 0 + _to_plain_decimal( _self_value( $self ) );
		},
	);

	return {
		BigNum => $bignum_class,
	};
}

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::Math::BigNum >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
