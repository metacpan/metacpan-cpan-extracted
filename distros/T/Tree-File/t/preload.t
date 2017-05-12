use strict;
use warnings;

use Test::More 'no_plan';
use YAML;

BEGIN { use_ok("Tree::File::YAML"); }

my $config;

$config = Tree::File::YAML->new("examples/simple", { preload => 1 });

isa_ok($config,                 "Tree::File::YAML", "the root");

isa_ok($config->{data}{armies},              "HASH", "1-deep dir, preloaded");
isa_ok($config->{data}{armies}{data}{german},"CODE", "2-deep dir, promised");

$config = Tree::File::YAML->new("examples/simple", { preload => -1 });

isa_ok($config,                 "Tree::File::YAML", "the root");

isa_ok($config->{data}{armies},              "HASH", "1-deep dir, preloaded");
isa_ok($config->{data}{armies}{data}{german},"HASH", "2-deep dir, preloaded");
