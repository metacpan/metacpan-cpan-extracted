#!perl 

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::RobotRules::DBIC' );
}

diag( "Testing WWW::RobotRules::DBIC $WWW::RobotRules::DBIC::VERSION, Perl $], $^X" );
