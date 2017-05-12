#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Toader::Entry::Manage' ) || print "Bail out!
";
}

diag( "Testing Toader::Entry::Manage $Toader::Entry::Manage::VERSION, Perl $], $^X" );
