#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::UMLSKS::Similarity' ) || print "Bail out!
";
}

diag( "Testing WebService::UMLSKS::Similarity $WebService::UMLSKS::Similarity::VERSION, Perl $], $^X" );
