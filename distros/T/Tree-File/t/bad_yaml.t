use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok("Tree::File::YAML"); }

eval { my $config = Tree::File::YAML->new("examples/bad_yaml"); };

like($@, qr/multiple sections/, "can't load multipart YAML document");
