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

is_deeply(
  $tree->get("aliens/invaders"),
  $data->{aliens}{invaders},
  "the alien invaders (path without leading /)"
);

isa_ok(
  $tree->set("aliens/invaders", { good => 5, bad => [ qw(one two three) ] }),
  'Tree::File::YAML',
  "set value and it become a tree"
);

is_deeply(
  $tree->get("aliens/invaders")->data,
  { good => 5, bad => [ qw(one two three) ] },
  "the new tree contains the right data"
);

is(
  $tree->set("music/tom_waits", "awesome"),
  "awesome",
  "set on new branch, autovivifying"
);

$tree->move("armies/german/soldiers" => "armies/american/prisoners");

is($tree->get("armies/german/soldiers"), undef, "old branch is gone");

is_deeply(
  $tree->get("armies/american/prisoners"),
  [qw(schultz klink)],
  "new branch is in place"
);

$tree->move("armies/german" => "armies/west_german");

is($tree->get("armies/german"), undef, "old branch is gone");

isa_ok(
  $tree->get("armies/west_german"),
  "Tree::File::YAML",
  "new branch in place"
);
