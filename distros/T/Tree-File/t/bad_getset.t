use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok("Tree::File::YAML"); }

my $tree = Tree::File::YAML->new("examples/simplest");

isa_ok($tree, "Tree::File::YAML");

for my $method (qw(get set delete)) {
  eval { $tree->$method(); };
  like($@, qr/without property/, "$method requires an identifier");
}

eval { $tree->type('pickle_sandwich'); };
like($@, qr/invalid branch type/, "die on invalid branch type");
