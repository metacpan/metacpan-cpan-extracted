#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Render::supportedBackends' ) || print "Bail out!
";
}

diag( "Testing Toader::Render::supportedBackends $Toader::Render::supportedBackends::VERSION, Perl $], $^X" );
