#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::Pod::Coverage::Permissive' ) || print "Bail out!
";
}

diag( "Testing Test::Pod::Coverage::Permissive $Test::Pod::Coverage::Permissive::VERSION, Perl $], $^X" );
