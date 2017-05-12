#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Text::MarkPerl' ) || print "Bail out!\n";
}

diag( "Testing Text::MarkPerl $Text::MarkPerl::VERSION, Perl $], $^X" );
