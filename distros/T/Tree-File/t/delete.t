use strict;
use warnings;

use Test::More 'no_plan';
use YAML;

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
isa_ok($config->get("aliens"), "Tree::File::YAML", "the first nested dir");

is_deeply(
  $config->get("aliens/invaders"),
  $data->{aliens}{invaders},
  "the alien invaders (path without leading /)"
);

is_deeply(
  $config->delete("aliens/invaders"),
  $data->{aliens}{invaders},
  "delete and return value"
);

is($config->get("aliens/invaders"), undef, "deleted value is gone");
