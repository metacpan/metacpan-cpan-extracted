use strict;
use warnings;

use Test::More 'no_plan';

use File::Path;
use File::Temp;

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

is_deeply($tree->data, $data, "total initial data matches");

my $tmpdir = File::Temp::tempdir( CLEANUP => 1 );

File::Path::rmtree($tmpdir); # to ensure that it will be created on request

# write out the tree unchanged
$tree->write($tmpdir);
ok(1, "survived writing of unchanged copy");

# read the written copy and compare it
my $copied = Tree::File::YAML->new($tmpdir);
isa_ok($copied, "Tree::File::YAML");

is_deeply($tree->data, $copied->data, "copied and reloaded unchanged");

ok(-d "$tmpdir",         "simple (root) created as a dir");
ok(-f "$tmpdir/stooges", "simple/stooges created as a normal file");
ok(-d "$tmpdir/armies",  "simple/armies created as a dir");

# modify and write out one branch of the tree
ok(
  $copied->set("/armies/german/soldiers", [qw(hans dieter)]),
  "replace a value"
);
$copied->get("/armies")->write();
ok(1, "survived writing of a branch");

# re-read the tree and compare it to the original
$copied = Tree::File::YAML->new($tmpdir);
my $expected = $data;
$expected->{armies}{german}{soldiers} = [ qw(hans dieter)];
is_deeply($expected, $copied->data, "written and reloaded unchanged");

# make a change, write out the whole tree, and compare it
is_deeply($copied->set("armies/german/prisoners", []), [], "armistice!");

$copied->write;
ok(1, "survived writing of changed copy");

my $reloaded = Tree::File::YAML->new($tmpdir);
isa_ok($reloaded, "Tree::File::YAML");

is_deeply($reloaded->get("armies/german/prisoners"), [], "changes retained");
