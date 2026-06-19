package Zuzu::Marshal::CBOR;

use utf8;

our $VERSION = '0.006000';

use Exporter qw( import );
use B qw( SVf_IOK SVf_NOK SVf_POK svref_2object );
use Encode ();
use Scalar::Util qw( blessed );
use Types::Serialiser ();
use Zuzu::Util::Number qw( is_finite_number );

use CBOR::Free ();
use CBOR::Free::Decoder ();

our @EXPORT_OK = qw(
	byte_string
	bytes_value
	cbor_false
	cbor_true
	decode_one
	encode_one
	is_byte_string
	is_cbor_bool
	is_tagged
	is_text_string
	tag
	tag_number
	tag_value
	text_string
	text_value
	validate_profile
);

use constant MAX_SAFE_INTEGER => 9007199254740991;

{
	package Zuzu::Marshal::CBOR::TextString;
	use Moo;
	has 'value' => ( is => 'ro', required => 1 );
}

{
	package Zuzu::Marshal::CBOR::ByteString;
	use Moo;
	has 'bytes' => ( is => 'ro', required => 1 );
}

{
	package Zuzu::Marshal::CBOR::Tagged;
	use Moo;
	has 'tag' => ( is => 'ro', required => 1 );
	has 'value' => ( is => 'ro' );
}

sub text_string {
	my ( $value ) = @_;
	$value //= '';
	return Zuzu::Marshal::CBOR::TextString->new( value => "$value" );
}

sub byte_string {
	my ( $bytes ) = @_;
	$bytes //= '';
	return Zuzu::Marshal::CBOR::ByteString->new(
		bytes => _bytes_scalar($bytes),
	);
}

sub tag {
	my ( $tag, $value ) = @_;
	return Zuzu::Marshal::CBOR::Tagged->new(
		tag => 0 + $tag,
		value => $value,
	);
}

sub cbor_true  { Types::Serialiser::true() }
sub cbor_false { Types::Serialiser::false() }

sub is_cbor_bool {
	my ( $value ) = @_;
	return Types::Serialiser::is_bool($value) ? 1 : 0;
}

sub is_text_string {
	my ( $value ) = @_;
	return blessed($value)
		&& $value->isa('Zuzu::Marshal::CBOR::TextString') ? 1 : 0;
}

sub is_byte_string {
	my ( $value ) = @_;
	return blessed($value)
		&& $value->isa('Zuzu::Marshal::CBOR::ByteString') ? 1 : 0;
}

sub is_tagged {
	my ( $value ) = @_;
	return blessed($value)
		&& $value->isa('Zuzu::Marshal::CBOR::Tagged') ? 1 : 0;
}

sub text_value {
	my ( $value ) = @_;
	die "Not a CBOR text string" if !is_text_string($value);
	return $value->value;
}

sub bytes_value {
	my ( $value ) = @_;
	die "Not a CBOR byte string" if !is_byte_string($value);
	return $value->bytes;
}

sub tag_number {
	my ( $value ) = @_;
	die "Not a CBOR tagged value" if !is_tagged($value);
	return $value->tag;
}

sub tag_value {
	my ( $value ) = @_;
	die "Not a CBOR tagged value" if !is_tagged($value);
	return $value->value;
}

sub encode_one {
	my ( $item ) = @_;
	my $bytes = CBOR::Free::encode( _to_cbor_free($item) );
	validate_profile($bytes);
	return $bytes;
}

sub decode_one {
	my ( $bytes ) = @_;
	$bytes = _bytes_scalar($bytes);
	validate_profile($bytes);
	my $decoder = CBOR::Free::Decoder->new->set_tag_handlers(
		55799 => sub {
			return Zuzu::Marshal::CBOR::Tagged->new(
				tag => 55799,
				value => $_[0],
			);
		},
	);
	return _from_cbor_free( $decoder->decode($bytes) );
}

sub validate_profile {
	my ( $bytes ) = @_;
	$bytes = _bytes_scalar($bytes);
	my $offset = _scan_item( \$bytes, 0, 1 );
	if ( $offset != length($bytes) ) {
		die "Invalid Zuzu Marshal CBOR: trailing bytes after item";
	}

	return 1;
}

sub _scan_item {
	my ( $bytes_ref, $offset, $top_level ) = @_;

	_require_available( $bytes_ref, $offset, 1, 'initial byte' );
	my $initial = unpack( 'C', substr( $$bytes_ref, $offset, 1 ) );
	$offset++;

	my $major = int( $initial / 32 );
	my $ai = $initial % 32;
	die "Invalid Zuzu Marshal CBOR: indefinite-length item"
		if $ai == 31;
	die "Invalid Zuzu Marshal CBOR: reserved additional information"
		if $ai >= 28 and $ai <= 30;

	if ( $major == 7 ) {
		return _scan_simple_or_float( $bytes_ref, $offset, $ai );
	}

	my ( $value, $next ) = _read_argument( $bytes_ref, $offset, $ai );
	$offset = $next;

	if ( $major == 0 ) {
		_assert_unsigned_number_range($value);
		return $offset;
	}
	if ( $major == 1 ) {
		_assert_negative_number_range($value);
		return $offset;
	}
	if ( $major == 2 or $major == 3 ) {
		_require_available( $bytes_ref, $offset, $value, 'string payload' );
		return $offset + $value;
	}
	if ( $major == 4 ) {
		for ( 1 .. $value ) {
			$offset = _scan_item( $bytes_ref, $offset, 0 );
		}
		return $offset;
	}
	if ( $major == 5 ) {
		for ( 1 .. $value ) {
			$offset = _scan_item( $bytes_ref, $offset, 0 );
			$offset = _scan_item( $bytes_ref, $offset, 0 );
		}
		return $offset;
	}
	if ( $major == 6 ) {
		die "Invalid Zuzu Marshal CBOR: unsupported tag $value"
			if !$top_level or $value != 55799;
		return _scan_item( $bytes_ref, $offset, 0 );
	}

	die "Invalid Zuzu Marshal CBOR: unsupported major type";
}

sub _scan_simple_or_float {
	my ( $bytes_ref, $offset, $ai ) = @_;

	return $offset if $ai == 20 or $ai == 21 or $ai == 22;
	die "Invalid Zuzu Marshal CBOR: unsupported simple value"
		if $ai < 24 or $ai == 24;
	die "Invalid Zuzu Marshal CBOR: half-precision float is invalid"
		if $ai == 25;
	die "Invalid Zuzu Marshal CBOR: single-precision float is invalid"
		if $ai == 26;
	if ( $ai == 27 ) {
		_require_available( $bytes_ref, $offset, 8, 'binary64 float' );
		my $float = unpack( 'd>', substr( $$bytes_ref, $offset, 8 ) );
		die "Invalid Zuzu Marshal CBOR: NaN is invalid"
			if $float != $float;
		die "Invalid Zuzu Marshal CBOR: infinite float is invalid"
			if !is_finite_number($float);
		return $offset + 8;
	}

	die "Invalid Zuzu Marshal CBOR: unsupported simple value";
}

sub _read_argument {
	my ( $bytes_ref, $offset, $ai ) = @_;

	return ( $ai, $offset ) if $ai < 24;
	if ( $ai == 24 ) {
		_require_available( $bytes_ref, $offset, 1, 'uint8 argument' );
		my $value = unpack( 'C', substr( $$bytes_ref, $offset, 1 ) );
		_assert_shortest_argument( $value, 24 );
		return ( $value, $offset + 1 );
	}
	if ( $ai == 25 ) {
		_require_available( $bytes_ref, $offset, 2, 'uint16 argument' );
		my $value = unpack( 'n', substr( $$bytes_ref, $offset, 2 ) );
		_assert_shortest_argument( $value, 256 );
		return ( $value, $offset + 2 );
	}
	if ( $ai == 26 ) {
		_require_available( $bytes_ref, $offset, 4, 'uint32 argument' );
		my $value = unpack( 'N', substr( $$bytes_ref, $offset, 4 ) );
		_assert_shortest_argument( $value, 65536 );
		return ( $value, $offset + 4 );
	}
	if ( $ai == 27 ) {
		_require_available( $bytes_ref, $offset, 8, 'uint64 argument' );
		my ( $hi, $lo ) = unpack( 'NN', substr( $$bytes_ref, $offset, 8 ) );
		my $value = $hi * 4294967296 + $lo;
		_assert_shortest_argument( $value, 4294967296 );
		return ( $value, $offset + 8 );
	}

	die "Invalid Zuzu Marshal CBOR: unsupported argument width";
}

sub _assert_shortest_argument {
	my ( $value, $minimum ) = @_;

	die "Invalid Zuzu Marshal CBOR: non-shortest integer or length"
		if $value < $minimum;
}

sub _assert_unsigned_number_range {
	my ( $value ) = @_;

	die "Invalid Zuzu Marshal CBOR: integer outside Zuzu Number range"
		if $value > MAX_SAFE_INTEGER;
}

sub _assert_negative_number_range {
	my ( $value ) = @_;

	die "Invalid Zuzu Marshal CBOR: integer outside Zuzu Number range"
		if $value > MAX_SAFE_INTEGER - 1;
}

sub _require_available {
	my ( $bytes_ref, $offset, $length, $label ) = @_;

	die "Invalid Zuzu Marshal CBOR: incomplete $label"
		if $length < 0 or $offset + $length > length($$bytes_ref);
}

sub _to_cbor_free {
	my ( $value ) = @_;

	return undef if !defined $value;
	return CBOR::Free::tag( $value->tag, _to_cbor_free( $value->value ) )
		if is_tagged($value);
	return _text_scalar( $value->value ) if is_text_string($value);
	return _bytes_scalar( $value->bytes ) if is_byte_string($value);
	return $value if is_cbor_bool($value);

	if ( ref($value) eq 'ARRAY' ) {
		return [ map { _to_cbor_free($_) } @{ $value } ];
	}
	if ( ref($value) eq 'HASH' ) {
		return {
			map {
				_text_scalar($_) => _to_cbor_free( $value->{$_} )
			} sort CORE::keys %{ $value }
		};
	}
	if ( ref($value) ) {
		die "Unsupported CBOR adapter value: " . ref($value);
	}

	return $value if _scalar_is_number($value);
	return _text_scalar($value);
}

sub _from_cbor_free {
	my ( $value ) = @_;

	return undef if !defined $value;
	if ( is_tagged($value) ) {
		return tag( $value->tag, _from_cbor_free( $value->value ) );
	}
	if ( ref($value) eq 'ARRAY' ) {
		return [ map { _from_cbor_free($_) } @{ $value } ];
	}
	if ( ref($value) eq 'HASH' ) {
		return {
			map {
				$_ => _from_cbor_free( $value->{$_} )
			} sort CORE::keys %{ $value }
		};
	}
	if ( ref($value) ) {
		return $value if is_cbor_bool($value);
		die "Unsupported decoded CBOR adapter value: " . ref($value);
	}

	return $value if _scalar_is_number($value);
	return utf8::is_utf8($value)
		? text_string($value)
		: byte_string($value);
}

sub _text_scalar {
	my ( $value ) = @_;
	$value //= '';
	return Encode::decode(
		'UTF-8',
		Encode::encode( 'UTF-8', "$value", Encode::FB_CROAK ),
		Encode::FB_CROAK,
	);
}

sub _bytes_scalar {
	my ( $value ) = @_;
	$value //= '';
	my $bytes = "$value";
	utf8::encode($bytes) if utf8::is_utf8($bytes);
	utf8::downgrade( $bytes, 1 )
		or die "CBOR byte string contains non-byte characters";
	return $bytes;
}

sub _scalar_is_number {
	my ( $value ) = @_;
	return 0 if ref($value);
	my $flags = svref_2object(\$value)->FLAGS;
	return ( $flags & ( SVf_IOK | SVf_NOK ) ) && !( $flags & SVf_POK )
		? 1
		: 0;
}

1;

=pod

=head1 NAME

Zuzu::Marshal::CBOR - narrow CBOR adapter for Zuzu Marshal

=head1 DESCRIPTION

Wraps C<CBOR::Free> behind explicit operations for the CBOR data types
used by Zuzu Marshal.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Marshal::CBOR >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
