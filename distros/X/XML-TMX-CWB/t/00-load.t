#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'XML::TMX::CWB' ) || print "Bail out!
";
}

diag( "Testing XML::TMX::CWB $XML::TMX::CWB::VERSION, Perl $], $^X" );
