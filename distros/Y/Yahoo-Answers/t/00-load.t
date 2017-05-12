#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Yahoo::Answers' ) || print "Bail out!
";
}

diag( "Testing Yahoo::Answers $Yahoo::Answers::VERSION, Perl $], $^X" );
