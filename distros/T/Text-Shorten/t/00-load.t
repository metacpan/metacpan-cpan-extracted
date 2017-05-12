#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Text::Shorten' ) || print "Bail out!
";
}

diag( "Testing Text::Shorten $Text::Shorten::VERSION, Perl $], $^X" );
