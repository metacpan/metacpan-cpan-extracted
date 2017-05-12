#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Twitpic::Fetch' );
}

diag( "Testing WWW::Twitpic::Fetch $WWW::Twitpic::Fetch::VERSION, Perl $], $^X" );
