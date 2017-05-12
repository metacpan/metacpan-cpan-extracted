#########################

use Test::More tests => 1;
BEGIN { use_ok('Win32::MBCS') };

#########################

if( 0 ) {
	$str = "abcd\x{4e2d}\x{6587}";
	Win32::MBCS::Utf8ToLocal( $str );
	printf "Utf8ToLocal = %s\n", $str;

	use Encode;
	Win32::MBCS::LocalToUtf8( $str );
	printf "LocalToUtf8 = %s\n", Encode::encode("gbk", $str);
}