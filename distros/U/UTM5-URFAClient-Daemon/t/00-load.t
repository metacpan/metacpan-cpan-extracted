use Test::More tests => 1;

BEGIN {
    use_ok( 'UTM5::URFAClient::Daemon' ) || print "Bail out!
";
}

diag( "Testing UTM5::URFAClient::Daemon $UTM5::URFAClient::Daemon::VERSION, Perl $], $^X" );
