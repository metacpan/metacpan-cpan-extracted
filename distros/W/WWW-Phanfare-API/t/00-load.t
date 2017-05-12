#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::Phanfare::API' ) || print "Bail out!
";
}

diag( "Testing WWW::Phanfare::API $WWW::Phanfare::API::VERSION, Perl $], $^X" );
