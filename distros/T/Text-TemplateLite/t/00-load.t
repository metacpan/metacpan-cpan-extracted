#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Text::TemplateLite' ) || print "Bail out!\n";
}

diag( "Testing Text::TemplateLite $Text::TemplateLite::VERSION, Perl $], $^X" );
