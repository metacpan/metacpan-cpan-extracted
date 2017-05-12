#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::VCS' ) || print "Bail out!
";
}

diag( "Testing Toader::VCS $Toader::VCS::VERSION, Perl $], $^X" );
