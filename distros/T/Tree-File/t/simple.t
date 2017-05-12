use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok("Tree::File::YAML"); }

my $tree = Tree::File::YAML->new("examples/simplest");

isa_ok($tree, "Tree::File::YAML");

is($tree->type(), undef, "it's a file-based tree (so, type undef)");

is($tree->type('dir'),   'dir', "set branch to dir type");
is($tree->type('file'), 'file', "set branch to file type");
is($tree->type(undef),   undef, "set branch to undef type");

is($tree->get("date"), "November 5th", "simplest: get date");

is_deeply(
  $tree->get("events"),
  [ "gunpowder treason", "plot" ],
  "simplest: get events"
);

is_deeply(
  [ sort $tree->node_names() ],
  [ qw(date events)          ],
  "get all top-level keys"
);

is_deeply(
  $tree->data,
  { date => "November 5th", events => [ "gunpowder treason", "plot" ] },
  "dump all tree data"
);

is(
  $tree->get("/does/not/exist"),
  undef,
  "deep, non-existent branch returns undef"
);

is_deeply(
  $tree->get("/does/not/exist", 1)->data,
  {},
  "non-existent id autovivifies as requested"
);
