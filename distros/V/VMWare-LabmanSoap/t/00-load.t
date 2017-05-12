#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'VMWare::LabmanSoap' ) || print "Bail out!
";
}

diag( "Testing VMWare::LabmanSoap $VMWare::LabmanSoap::VERSION, Perl $], $^X" );
