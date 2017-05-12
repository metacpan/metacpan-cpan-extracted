#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Text::YAWikiFormater' ) || print "Bail out!\n";
}

diag( "Testing Text::YAWikiFormater $Text::YAWikiFormater::VERSION, Perl $], $^X" );
