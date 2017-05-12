#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Page::Manage' ) || print "Bail out!
";
}

diag( "Testing Toader::Page::Manage $Toader::Page::Manage::VERSION, Perl $], $^X" );
