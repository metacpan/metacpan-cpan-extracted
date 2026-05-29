use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;
use File::Spec;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new(
		lib => [
			File::Spec->catdir( File::Spec->curdir, "stdlib", "modules" ),
		],
	);
	my $ast = $parser->parse( $src, 'std-digest.zzs' );

	return $runtime->evaluate( $ast );
}

is eval_src(<<'SRC'), 1, 'std/digest/md5 returns expected encodings and BinaryString output';
from std/digest/md5 import md5, md5_hex, md5_b64;
let payload := to_binary( "abc" );
( ( typeof md5(payload) ) eq "BinaryString" )
	and ( length md5(payload) = 16 )
	and ( md5_hex(payload) eq "900150983cd24fb0d6963f7d28e17f72" )
	and ( md5_b64(payload) eq "kAFQmDzST7DWlj99KOF/cg" );
SRC


is eval_src(<<'SRC'), 1, 'std/digest/crc32 returns expected encodings and BinaryString output';
from std/digest/crc32 import crc32, crc32_hex, crc32_b64;
let payload := to_binary( "abc" );
( ( typeof crc32(payload) ) eq "BinaryString" )
	and ( length crc32(payload) = 4 )
	and ( crc32_hex(payload) eq "352441c2" )
	and ( crc32_b64(payload) eq "NSRBwg" );
SRC

is eval_src(<<'SRC'), 1, 'std/digest/sha returns expected sizes and selected vectors';
from std/digest/sha import *;
let payload := to_binary( "abc" );
let hmac_payload := to_binary( "The quick brown fox jumps over the lazy dog" );
let hmac_key := to_binary( "key" );
( ( typeof sha256(payload) ) eq "BinaryString" )
	and ( length sha1(payload) = 20 )
	and ( length sha224(payload) = 28 )
	and ( length sha256(payload) = 32 )
	and ( length sha384(payload) = 48 )
	and ( length sha512(payload) = 64 )
	and ( sha1_hex(payload) eq "a9993e364706816aba3e25717850c26c9cd0d89d" )
	and ( sha256_hex(payload) eq "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" )
	and ( sha512_b64(payload) eq "3a81oZNherrMQXNJriBBMRLm+k6JqX6iCp7u5ktV05ohkpkqJ0/BqDa6PCOj/uu9RU1EI2Q86A4qmslPpUyknw" )
	and ( hmac_sha256_hex( hmac_payload, hmac_key ) eq "f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8" )
	and ( hmac_sha256_b64( hmac_payload, hmac_key ) eq "97yD9DBThCSxMpjmqm+xQ+9NWaFJRhdZl0edvC0aPNg" )
	and ( ( typeof hmac_sha256( hmac_payload, hmac_key ) ) eq "BinaryString" )
	and ( length hmac_sha256( hmac_payload, hmac_key ) = 32 );
SRC

like dies {
	eval_src(<<'SRC');
from std/digest/md5 import md5_hex;
md5_hex( "abc" );
SRC
}, qr/TypeException: md5_hex expects BinaryString, got String/,
	'std/digest/md5 type check rejects String input';

like dies {
	eval_src(<<'SRC');
from std/digest/sha import sha256_b64;
sha256_b64( "abc" );
SRC
}, qr/TypeException: sha256_b64 expects BinaryString, got String/,
	'std/digest/sha type check rejects String input';

like dies {
	eval_src(<<'SRC');
from std/digest/sha import hmac_sha256;
hmac_sha256( to_binary( "abc" ), "key" );
SRC
}, qr/TypeException: hmac_sha256 expects BinaryString key, got String/,
	'std/digest/sha HMAC rejects String key input';


like dies {
	eval_src(<<'SRC');
from std/digest/crc32 import crc32;
crc32( "abc" );
SRC
}, qr/TypeException: 'value' must be BinaryString, got String/,
	'std/digest/crc32 type check rejects String input';

done_testing;
