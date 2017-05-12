#!perl -T

use Test::More tests => 2;
use lib 'lib/';

BEGIN {
	use_ok( 'Vim::Snippet::Completion' );
}

# diag( "Testing Vim::Snippet::Completion $Vim::Snippet::Converter::VERSION, Perl $], $^X" );

my $comp = new Vim::Snippet::Completion;
ok( $comp );

