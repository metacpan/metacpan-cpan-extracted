use Test::More tests => 2;

BEGIN {
  use_ok('Tree::File');
  use_ok('Tree::File::YAML');
}

diag( "Testing Tree::File $Tree::File::VERSION" );
