#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Zabbix::Sender' ) || print "Bail out!
";
}

diag( "Testing Zabbix::Sender $Zabbix::Sender::VERSION, Perl $], $^X" );
