#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'XML::GrammarBase' );
}

diag( "Testing XML::GrammarBase $XML::GrammarBase::VERSION, Perl $], $^X" );
