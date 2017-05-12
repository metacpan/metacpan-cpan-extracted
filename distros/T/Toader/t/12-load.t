#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Render::supportedObjects' ) || print "Bail out!
";
}

diag( "Testing Toader::Render::supportedObjects $Toader::Render::supportedObjects::VERSION, Perl $], $^X" );
