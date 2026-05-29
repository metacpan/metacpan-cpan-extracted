use Test2::V0;

use Types::Serialiser ();
use Zuzu::Marshal::CBOR qw(
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

my $envelope = tag(
	55799,
	[
		text_string('ZUZU-MARSHAL'),
		1,
		{},
		undef,
		[],
		[],
	],
);

my $envelope_blob = encode_one($envelope);
is(
	unpack( 'H*', $envelope_blob ),
	'd9d9f7866c5a555a552d4d41525348414c01a0f68080',
	'encode tagged envelope header',
);

my $envelope_roundtrip = decode_one($envelope_blob);
ok is_tagged($envelope_roundtrip), 'decode preserves top-level tag';
is tag_number($envelope_roundtrip), 55799, 'top-level tag number';
is text_value( tag_value($envelope_roundtrip)->[0] ),
	'ZUZU-MARSHAL',
	'envelope magic is text';
is tag_value($envelope_roundtrip)->[1], 1, 'envelope version';

is decode_one( encode_one(undef) ), undef, 'null round trip';
ok is_cbor_bool( decode_one( encode_one( cbor_true() ) ) ),
	'true round trip preserves CBOR boolean type';
ok decode_one( encode_one( cbor_true() ) ) ? 1 : 0,
	'true round trip preserves truth';
ok !decode_one( encode_one( cbor_false() ) ),
	'false round trip preserves falsehood';
is decode_one( encode_one(42) ), 42, 'integer round trip';
is decode_one( encode_one(3.25) ), 3.25, 'float round trip';

my $text_roundtrip = decode_one( encode_one( text_string('cafe') ) );
ok is_text_string($text_roundtrip), 'text string round trip keeps type';
is text_value($text_roundtrip), 'cafe', 'text string payload';

my $bytes_roundtrip = decode_one(
	encode_one( byte_string( pack( 'H*', '0001ff' ) ) ),
);
ok is_byte_string($bytes_roundtrip), 'byte string round trip keeps type';
is unpack( 'H*', bytes_value($bytes_roundtrip) ),
	'0001ff',
	'byte string payload';

my $array_roundtrip = decode_one(
	encode_one( [ text_string('x'), byte_string('y'), 7 ] ),
);
ok is_text_string( $array_roundtrip->[0] ), 'array text item type';
ok is_byte_string( $array_roundtrip->[1] ), 'array byte item type';
is $array_roundtrip->[2], 7, 'array number item';

my $map_roundtrip = decode_one(
	encode_one(
		{
			alpha => text_string('a'),
			beta => byte_string('b'),
		}
	),
);
ok is_text_string( $map_roundtrip->{alpha} ), 'map text value type';
ok is_byte_string( $map_roundtrip->{beta} ), 'map byte value type';

ok validate_profile($envelope_blob), 'profile validation accepts envelope';

sub _bytes {
	my ( $hex ) = @_;
	return pack( 'H*', $hex );
}

like dies { decode_one( _bytes('f600') ) },
	qr/trailing bytes/,
	'decode rejects trailing bytes';
like dies { decode_one( _bytes('18') ) },
	qr/incomplete uint8 argument/,
	'decode rejects incomplete values';
like dies { decode_one( _bytes('1801') ) },
	qr/non-shortest/,
	'decode rejects non-shortest integers';
like dies { decode_one( _bytes('5f40ff') ) },
	qr/indefinite-length/,
	'decode rejects indefinite byte strings';
like dies { decode_one( _bytes('9fff') ) },
	qr/indefinite-length/,
	'decode rejects indefinite arrays';
like dies { decode_one( _bytes('f7') ) },
	qr/unsupported simple value/,
	'decode rejects undefined simple value';
like dies { decode_one( _bytes('f818') ) },
	qr/unsupported simple value/,
	'decode rejects extended simple values';
like dies { decode_one( _bytes('c16178') ) },
	qr/unsupported tag 1/,
	'decode rejects unsupported top-level tags';
like dies { decode_one( _bytes('81d9d9f76178') ) },
	qr/unsupported tag 55799/,
	'decode rejects nested tag 55799';
like dies { decode_one( _bytes('f93c00') ) },
	qr/half-precision/,
	'decode rejects half-precision floats';
like dies { decode_one( _bytes('fa3f800000') ) },
	qr/single-precision/,
	'decode rejects single-precision floats';
like dies { decode_one( _bytes('fb7ff8000000000000') ) },
	qr/NaN/,
	'decode rejects NaN';
like dies { decode_one( _bytes('fb7ff0000000000000') ) },
	qr/infinite float/,
	'decode rejects infinity';
like dies { decode_one( _bytes('1b0020000000000000') ) },
	qr/outside Zuzu Number range/,
	'decode rejects out-of-range unsigned integers';
like dies { decode_one( _bytes('3b001fffffffffffff') ) },
	qr/outside Zuzu Number range/,
	'decode rejects out-of-range negative integers';
like dies { encode_one( tag( 1, text_string('x') ) ) },
	qr/unsupported tag 1/,
	'encode rejects unsupported tags';

done_testing;
