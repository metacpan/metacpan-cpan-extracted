#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Templates::Defaults' ) || print "Bail out!
";
}

diag( "Testing Toader::Templates::Defaults $Toader::Templates::Defaults::VERSION, Perl $], $^X" );
