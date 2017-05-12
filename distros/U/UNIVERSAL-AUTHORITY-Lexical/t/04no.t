package Local::Test;

BEGIN { $Local::Test::AUTHORITY = 'http://example.net/'; }

package main;

use Test::More tests => 4;
use UNIVERSAL::AUTHORITY::Lexical;

ok( eval{ Local::Test->AUTHORITY} );

{
	ok( eval{Local::Test->AUTHORITY} );
	no UNIVERSAL::AUTHORITY::Lexical;
	ok( !eval{Local::Test->AUTHORITY} );
}

ok( eval{Local::Test->AUTHORITY} );
