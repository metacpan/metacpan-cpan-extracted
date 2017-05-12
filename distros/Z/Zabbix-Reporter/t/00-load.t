#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Zabbix::Reporter' ) || print "Bail out!
";
}

diag( "Testing Zabbix::Reporter $Zabbix::Reporter::VERSION, Perl $], $^X" );
