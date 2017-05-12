#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::Markdown::ApacheHandler' );
}

diag( "Testing Text::Markdown::ApacheHandler $Text::Markdown::ApacheHandler::VERSION, Perl $], $^X" );
