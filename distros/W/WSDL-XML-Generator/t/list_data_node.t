#!perl -T

use lib 'lib';
use lib 't';
use Test::More tests => 1;

BEGIN {
    use_ok( 'WSDL::XML::Generator' ) || print "Bail out!\n";
}

use WSDL::XML::Generator qw( list_data_node );
list_data_node('t/InternalQA.wsdl');
