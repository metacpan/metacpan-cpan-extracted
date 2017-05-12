#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::RDF' ) || print "Bail out!
";
}

diag( "Testing Test::RDF $Test::RDF::VERSION, RDF::Trine $RDF::Trine::VERSION, Perl $], $^X" );
