#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Entry::Helper' ) || print "Bail out!
";
}

diag( "Testing Toader::Entry::Helper $Toader::Entry::Helper::VERSION, Perl $], $^X" );
