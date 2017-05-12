use strict;
use warnings;

use Test::More 'no_plan';

use File::Temp;

BEGIN { use_ok("Tree::File::YAML"); }

my $data = { aliens => { invaders   => [ qw(zim v orbs decepticons)    ],
                         'lost way' => [ "alf", "ray walston", "e.t."  ] },
             armies => { german     => { soldiers  => [ qw(schultz klink) ],
                                         prisoners => [ "hogan", "chuck norris",
                                                        "the rest of the gang" ] } },
             stooges=> [ qw(larry moe curly shemp) ]
           };

{ # write out to new place, collapsed

  my $config = Tree::File::YAML->new("examples/simple");

  isa_ok($config,                "Tree::File::YAML", "the root");

  is_deeply($config->data, $data, "total initial data matches");

  is($config->collapse, 'file', "collapse entire tree");

  my $tmpdir = File::Temp::tempdir( CLEANUP => 1 );

  $config->write($tmpdir);
  ok(1, "survived writing");

  my $copied = Tree::File::YAML->new($tmpdir);
  isa_ok($copied, "Tree::File::YAML");

  is_deeply($config->data, $copied->data, "copied and reloaded unchanged");

  ok(-f "$tmpdir",           "simple (root) created as a file");
  ok(! -f "$tmpdir/stooges", "simple/stooges is not a disk entity");
  ok(! -d "$tmpdir/armies",  "simple/armies is not a disk entity");
}

{ # write out to the same place place, collapsed (so, remove that dir!)
  my $config = Tree::File::YAML->new("examples/simple");

  isa_ok($config,                "Tree::File::YAML", "the root");

  is_deeply($config->data, $data, "total initial data matches");

  my $tmpdir = File::Temp::tempdir( CLEANUP => 1 );

  $config->write($tmpdir);
  ok(1, "survived writing");

  my $copied = Tree::File::YAML->new($tmpdir);
  isa_ok($copied, "Tree::File::YAML");

  is_deeply($config->data, $copied->data, "copied and reloaded unchanged");

  ok(-d "$tmpdir",         "simple (root) created as a file");
  ok(-f "$tmpdir/stooges", "simple/stooges is not a disk entity");
  ok(-d "$tmpdir/armies",  "simple/armies is not a disk entity");

  $copied->collapse();
  $copied->write();

  ok(-f "$tmpdir",           "simple (root) created as a file");
  ok(! -f "$tmpdir/stooges", "simple/stooges is not a disk entity");
  ok(! -d "$tmpdir/armies",  "simple/armies is not a disk entity");
}
