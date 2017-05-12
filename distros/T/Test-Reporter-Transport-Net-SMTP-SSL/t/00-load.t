#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::Reporter::Transport::Net::SMTP::SSL' ) || print "Bail out!
";
}

diag( "Testing Test::Reporter::Transport::Net::SMTP::SSL $Test::Reporter::Transport::Net::SMTP::SSL::VERSION, Perl $], $^X" );
