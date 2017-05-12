#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::MultiMarkdown::ApacheHandler' );
}

diag( "Testing Text::MultiMarkdown::ApacheHandler $Text::MultiMarkdown::ApacheHandler::VERSION, Perl $], $^X" );
