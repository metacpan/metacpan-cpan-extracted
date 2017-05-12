package Local::MyTest;

our $AUTHORITY = 'http://example.net/';

package main;

use Test::More tests => 7;
use Test::Exception;
use UNIVERSAL::AUTHORITY::Lexical;

dies_ok
	{ Local::MyTest->AUTHORITY('cpan:TOBYINK') }
	'dies passed string';

dies_ok
	{ Local::MyTest->AUTHORITY(qr/^cpan:/i) }
	'dies passed regexp';

dies_ok
	{ Local::MyTest->AUTHORITY(undef) }
	'dies passed undef';
	
dies_ok
	{ Local::MyTest->AUTHORITY(['mailto:joe@example.net' , qr/^cpan:/i]) }
	'dies passed arrayref';

lives_ok
	{ Local::MyTest->AUTHORITY('http://example.net/') }
	'lives passed string';

lives_ok
	{ Local::MyTest->AUTHORITY(qr/^http:/i) }
	'lives passed regexp';

lives_ok
	{ Local::MyTest->AUTHORITY(['mailto:joe@example.net' , qr/^cpan:/i, 'http://example.net/']) }
	'lives passed arrayref';
