#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'XML::Debian::ENetInterfaces' ) || print "Bail out!
";
}

diag( "Testing XML::Debian::ENetInterfaces $XML::Debian::ENetInterfaces::VERSION, Perl $], $^X" );
