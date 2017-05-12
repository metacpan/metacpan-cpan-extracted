#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Text::SpanningTable' ) || print "Bail out!
";
}

diag( "Testing Text::SpanningTable $Text::SpanningTable::VERSION, Perl $], $^X" );
