use strict;
use warnings;

use Test::More 'no_plan';

use File::Temp;

BEGIN { use_ok("Tree::File::YAML"); }

my $tmpdir = File::Temp::tempdir( CLEANUP => 1, DIR => "examples");

my $config = Tree::File::YAML->new($tmpdir);

isa_ok($config, "Tree::File::YAML");

