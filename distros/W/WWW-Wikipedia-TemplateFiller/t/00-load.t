#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Wikipedia::TemplateFiller' );
}

diag( "Testing WWW::Wikipedia::TemplateFiller $WWW::Wikipedia::TemplateFiller::VERSION, Perl $], $^X" );
