#!perl -T

use lib 'lib';
use lib 't';
use Test::More tests => 1;

BEGIN {
    use_ok( 'WSDL::XML::Generator' ) || print "Bail out!\n";
}

use WSDL::XML::Generator qw( write );
write('t/InternalQA.wsdl');
