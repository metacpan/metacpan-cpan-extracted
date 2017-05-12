use strict;
use warnings;

use Test::More 'no_plan';
use YAML;

BEGIN { use_ok("Tree::File"); }

eval { Tree::File->load_file() };
like($@, qr/unimplemented/, "load_file is an abstract method");

eval { Tree::File->write_file() };
like($@, qr/unimplemented/, "write_file is an abstract method");
