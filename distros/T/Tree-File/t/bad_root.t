use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok("Tree::File::YAML"); }

eval { my $config = Tree::File::YAML->new("examples/DOESNT_EXIST"); };
like($@, qr/doesn't exist/, "can't load missing root");

SKIP: {
  skip "can't test unreadability of a dir when root!", 1 if ($> == 0);

  mkdir "examples/unreadable" if not -d "examples/unreadable";

  chmod 0000, "examples/unreadable";

  eval { my $config = Tree::File::YAML->new("examples/unreadable"); };
  like($@, qr/can't open branch/, "can't load a-rx root");

  chmod 0644, "examples/unreadable";
  rmdir "examples/unreadable";
}
