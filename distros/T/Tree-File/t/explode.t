use strict;
use warnings;

use Test::More 'no_plan';

use File::Temp;

BEGIN { use_ok("Tree::File::YAML"); }

my $config = Tree::File::YAML->new("examples/simple");

my $data = { aliens => { invaders   => [ qw(zim v orbs decepticons)    ],
                         'lost way' => [ "alf", "ray walston", "e.t."  ] },
             armies => { german     => { soldiers  => [ qw(schultz klink) ],
                                         prisoners => [ "hogan", "chuck norris", 
                                                        "the rest of the gang" ] } },
             stooges=> [ qw(larry moe curly shemp) ]
           };

isa_ok($config,                "Tree::File::YAML", "the root");

is_deeply($config->data, $data, "total initial data matches");

is($config->get("/aliens")->explode, 'dir', "explode /aliens");

my $tmpdir = File::Temp::tempdir( CLEANUP => 1 );

$config->write($tmpdir);
ok(1, "survived writing");

my $copied = Tree::File::YAML->new($tmpdir);
isa_ok($copied, "Tree::File::YAML");

is_deeply($config->data, $copied->data, "copied and reloaded unchanged");

ok(-d "$tmpdir",        "simple (root) created as a dir");
ok(-d "$tmpdir/aliens", "simple/aliens written as a dir");
ok(-d "$tmpdir/armies", "simple/armies written as a dir");
