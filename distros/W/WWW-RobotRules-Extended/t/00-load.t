#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::RobotRules::Extended' ) || print "Bail out!\n";
}

diag( "Testing WWW::RobotRules::Extended $WWW::RobotRules::Extended::VERSION, Perl $], $^X" );
