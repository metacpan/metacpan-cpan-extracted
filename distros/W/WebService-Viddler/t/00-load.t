#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'WebService::Viddler' ) || print "Bail out!
";
    use_ok( 'WebService::Viddler' ) || print "Bail out!
";
}

diag( "Testing WebService::Viddler $WebService::Viddler::VERSION, Perl $], $^X" );
