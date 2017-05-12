use strict;
use warnings;

use Test::More 'no_plan';
use YAML;

BEGIN { use_ok("Tree::File::YAML"); }

my $config = Tree::File::YAML->new("examples/simple", {readonly => 1});

isa_ok($config,                "Tree::File::YAML", "the root");

eval { $config->set("aliens", 2) };
like($@, qr/readonly/, "can't call set on readonly tree");

eval { $config->delete("aliens") };
like($@, qr/readonly/, "can't call delete on readonly tree");

eval { $config->set("armies/german/prisoners", 2) };
like($@, qr/readonly/, "can't call deep set on readonly tree");

eval { $config->delete("armies/german/prisoners") };
like($@, qr/readonly/, "can't call deep delete on readonly tree");
