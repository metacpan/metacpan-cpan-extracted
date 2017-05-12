use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok("Tree::File::YAML"); }

{ # test default behavior
  my $tree = Tree::File::YAML->new("examples/simple");

  isa_ok($tree, "Tree::File::YAML");

  is(
    $tree->get("/armies/polish/heroes"),
    undef,
    "non-existent branch returns undef"
  );
}

{ # test with custom closure
#  my $not_found = sub {
#    my ($id, $node) = @_;
#    return "$id not found in $node";
#  };


  my $tree = Tree::File::YAML->new("examples/simple", { not_found => sub { 0 } });

  isa_ok($tree, "Tree::File::YAML");

  is(
    $tree->get("/armies/polish/heroes"),
    0,
    "custom not-found closure works"
  );
}
