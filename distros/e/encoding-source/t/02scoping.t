#!perl

use strict;
use warnings;
use Test::More;
plan tests => 13;

my ($a, $b);

{
    use encoding::source "greek";
    is( encoding::source->name, 'iso-8859-7', 'encoding name' );
    $a = "\xDF";
    $b = "\x{100}";
    is( ord($a), 0x3af );
    is( ord($b), 0x100 );
}
is( ord($a), 0x3af );
is( ord($b), 0x100 );

$a = "\xDF";
$b = "\x{100}";
is( ord($a), 0xdf );
is( ord($b), 0x100 );

{
    use encoding::source "utf8";
    is( ord("ß"), 0xdf );
    {
	no encoding::source;
	is( ord("ß"), 0xc3 );
    }
    is( ord("ß"), 0xdf, 'restored after unimport' );
    {
	use encoding::source 'latin1';
	is( ord("ß"), 0xc3 );
    }
    is( ord("ß"), 0xdf, 'restored after import' );
}
is( ord("ß"), 0xc3 );
