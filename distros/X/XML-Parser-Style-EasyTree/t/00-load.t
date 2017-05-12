#!/use/bin/perl -w

use Test::More;
use lib::abs '../lib';

BEGIN {
	my $w = 0;
	eval {require Test::NoWarnings;Test::NoWarnings->import; 1} and $w = 1;
	plan tests => 3+$w;
	use_ok( 'XML::Parser::Style::EasyTree' );
	use_ok( 'XML::Parser::Style::ETree' );
	is($XML::Parser::Style::EasyTree::VERSION, $XML::Parser::Style::ETree::VERSION, 'versions');
}

diag( "Testing XML::Parser::Style::ETree $XML::Parser::Style::ETree::VERSION, Perl $], $^X" );
