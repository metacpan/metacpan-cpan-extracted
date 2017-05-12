use Test::More tests => 1;

BEGIN {
    use_ok( 'UTM5::URFAClient' ) || print "Bail out!
";
}

diag( "Testing UTM5::URFAClient $UTM5::URFAClient::VERSION, Perl $], $^X" );
