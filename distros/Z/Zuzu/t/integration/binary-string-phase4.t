use Test2::V0;

use Zuzu::Parser;
use Zuzu::Runtime;

my $parser = Zuzu::Parser->new;

sub eval_src {
	my ( $src ) = @_;
	my $runtime = Zuzu::Runtime->new;
	my $ast = $parser->parse( $src, 'binary-string-phase4.zzs' );

	return $runtime->evaluate( $ast );
}

is eval_src(<<'SRC'), 1, 'std/io raw APIs use BinaryString and preserve non-UTF8 bytes';
from std/io import Path;
let file := Path.tempfile();
let raw := ~to_binary( "ABC" );
file.spew(raw);
let roundtrip := file.slurp();
( ( typeof roundtrip ) eq "BinaryString" )
	and ( length roundtrip = length raw )
	and ( roundtrip == raw );
SRC

is eval_src(<<'SRC'), 1, 'std/io utf8 APIs use String for multibyte text';
from std/io import Path;
let file := Path.tempfile();
let text := "héllö";
file.spew_utf8(text);
( file.slurp_utf8() eq text )
	and ( ( typeof file.slurp_utf8() ) eq "String" );
SRC

is eval_src(<<'SRC'), 1, 'explicit conversion flow works for binary and utf8 APIs';
from std/io import Path;
let file := Path.tempfile();
let source := "é";
file.spew( to_binary(source) );
( to_string( file.slurp() ) eq source );
SRC

is eval_src(<<'SRC'), 1, 'std/string/base64 boundaries use BinaryString payloads';
from std/string/base64 import encode, decode;
let raw := to_binary( "Hello, world!" );
let b64 := encode(raw);
let got := decode(b64);
( ( typeof b64 ) eq "String" )
	and ( ( typeof got ) eq "BinaryString" )
	and ( got == raw );
SRC

like dies {
	eval_src(<<'SRC');
from std/io import Path;
let file := Path.tempfile();
file.spew( "abc" );
SRC
}, qr/TypeException: Path\.spew expects BinaryString, got String/,
	'Path.spew rejects String input';

like dies {
	eval_src(<<'SRC');
from std/io import Path;
let file := Path.tempfile();
file.spew_utf8( to_binary( "abc" ) );
SRC
}, qr/TypeException: Path\.spew_utf8 expects String, got BinaryString/,
	'Path.spew_utf8 rejects BinaryString input';

like dies {
	eval_src(<<'SRC');
from std/string/base64 import encode;
encode( "abc" );
SRC
}, qr/TypeException: encode expects BinaryString, got String/,
	'base64 encode rejects String input';

like dies {
	eval_src(<<'SRC');
from std/string/base64 import decode;
decode( to_binary( "YWJj" ) );
SRC
}, qr/TypeException: decode expects String, got BinaryString/,
	'base64 decode rejects BinaryString input';

done_testing;
