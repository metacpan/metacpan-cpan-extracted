use strict;
use utf8;

no warnings 'utf8';

use Test::More tests => 14;
use Test::NoWarnings;

use Unicode::Normalize;

is( Unicode::Normalize::NFKC("\x{1FFF}"), "\x{1FFF}", 	'U+1FFF' );
is( Unicode::Normalize::NFKC("\x{2000}"), " ", 		'U+2000 EN QUAD' );
is( Unicode::Normalize::NFKC("\x{2001}"), " ", 		'U+2001 EM SPACE' );
is( Unicode::Normalize::NFKC("\x{2002}"), " ", 		'U+2002 EN SPACE' );
is( Unicode::Normalize::NFKC("\x{2003}"), " ", 		'U+2003 EM SPACE' );
is( Unicode::Normalize::NFKC("\x{2004}"), " ",		'U+2004 THREE-PER-EM SPACE' );
is( Unicode::Normalize::NFKC("\x{2005}"), " ",	 	'U+2005 FOUR-PER-EM SPACE' );
is( Unicode::Normalize::NFKC("\x{2006}"), " ", 		'U+2006 SIX-PER-EM SPACE' );
is( Unicode::Normalize::NFKC("\x{2007}"), " ", 		'U+2007 FIGURE SPACE' );
is( Unicode::Normalize::NFKC("\x{2008}"), " ", 		'U+2008 PUNCTUATION SPACE' );
is( Unicode::Normalize::NFKC("\x{2009}"), " ", 		'U+2009 THIN SPACE' );
is( Unicode::Normalize::NFKC("\x{200A}"), " ", 		'U+200A HAIR SPACE' );
is( Unicode::Normalize::NFKC("\x{200B}"), "\x{200B}",	'U+200B ZERO WIDTH SPACE' );

