#!perl -T

use lib 'lib';
use Test::More tests => 1;

BEGIN {
    use_ok( 'WSDL::XML::Generator' ) || print "Bail out!\n";
}

diag( "Testing WSDL::XML::Generator $WSDL::XML::Generator::VERSION, Perl $], $^X" );
