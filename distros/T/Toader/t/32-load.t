#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Gallery' ) || print "Bail out!
";
}

diag( "Testing Toader::Gallery $Toader::Gallery::VERSION, Perl $], $^X" );
