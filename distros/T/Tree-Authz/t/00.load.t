use Test::More tests => 2;

BEGIN {
use_ok( 'Tree::Authz' );
use_ok( 'Tree::Authz::Role' );
}

diag( "Testing Tree::Authz $Tree::Authz::VERSION" );
