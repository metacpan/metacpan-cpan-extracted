#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'VMware::LabManager' ) || print "Bail out!
";
}

diag( "Testing VMware::LabManager $VMware::LabManager::VERSION, Perl $], $^X" );
