#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'XML::LibXML::LazyMatcher' ) || print "Bail out!
";
}

diag( "Testing XML::LibXML::LazyMatcher $XML::LibXML::LazyMatcher::VERSION, Perl $], $^X" );
