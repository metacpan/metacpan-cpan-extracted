#!perl
use strict;
use warnings;

use Test::More 'no_plan';
use YAML;

BEGIN { use_ok("Tree::File::YAML"); }

my $tree = Tree::File::YAML->new("examples/simple");

my $data = { aliens => { invaders   => [ qw(zim v orbs decepticons)    ],
                         'lost way' => [ "alf", "ray walston", "e.t."  ] },
             armies => { german     => { soldiers  => [ qw(schultz klink) ],
                                         prisoners => [ "hogan", "chuck norris", 
                                                        "the rest of the gang" ] } },
             stooges=> [ qw(larry moe curly shemp) ]
           };

isa_ok($tree,                "Tree::File::YAML", "the root");
isa_ok($tree->get("aliens"), "Tree::File::YAML", "the first nested dir");

is($tree->type(), "dir", "it's a dir-based tree");

is_deeply(
  $tree->get("aliens")->get("invaders"),
  $data->{aliens}{invaders},
  "the alien invaders (chained gets)"
);

is_deeply(
  $tree->get("aliens/invaders"),
  $data->{aliens}{invaders},
  "the alien invaders (path without leading /)"
);

is_deeply(
  $tree->get("/aliens/invaders"),
  $data->{aliens}{invaders},
  "the alien invaders (path with leading /)"
);

is(
  $tree->get("/armies/german")->path(),
  "/armies/german",
  "get path of node"
);

is(
  $tree->get("/armies/german")->basename(),
  "german",
  "get basename of node"
);

is_deeply(
  [ $tree->node_names() ],
  [ sort keys %$data    ],
  "get all top-level keys"
);

my @nodes = $tree->nodes();
is(@nodes, 3, "there are three nodes");
isa_ok(shift(@nodes), "Tree::File::YAML", "first node is a tree");
isa_ok(shift(@nodes), "Tree::File::YAML", "second node is a tree");
isa_ok(shift(@nodes), "ARRAY",            "third node is an array");

is_deeply(
  [ sort $tree->branch_names() ],
  [ qw(aliens armies)          ],
  "get top-level branch names"
);

my @branches = $tree->branches();
is(@branches, 2, "there are two branches");
isa_ok(shift(@branches), "Tree::File::YAML", "first branch is a tree");
isa_ok(shift(@branches), "Tree::File::YAML", "second branch is a tree");

my @deep_nodes = $tree->node_names("/armies/german");
is(@deep_nodes, 2, "there are two deep nodes");
is_deeply([ sort @deep_nodes ],
	  [ qw(prisoners soldiers) ],
	  "deep node names are correct");

is_deeply(
  $tree->data,
  $data,
  "return entire structure"
);

is($tree->as_yaml, YAML::Dump($data), "dump to yaml");
