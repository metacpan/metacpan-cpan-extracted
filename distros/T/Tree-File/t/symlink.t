use strict;
use warnings;

use Test::More;

if (eval { symlink("",""); 1 }) { # i.e., can symlink files
  plan 'no_plan';
} else {
  plan skip_all => "no symlinks, so no symlink testing required"
}

use_ok("Tree::File::YAML");

unlink qw(examples/has_symlink/link_to_file examples/has_symlink/link_to_dir);

symlink "examples/has_symlink/file" => "examples/has_symlink/link_to_file";
symlink "examples/has_symlink/dir"  => "examples/has_symlink/link_to_dir";

my $config = Tree::File::YAML->new("examples/has_symlink");

isa_ok($config,                "Tree::File::YAML", "the root");
isa_ok($config->get("dir"),    "Tree::File::YAML", "the first nested dir");

is_deeply(
  $config->get("/file/alphabet"),
  [ qw(a b c d e f g h i j k l m n o p q r s t u v w x y z) ],
  "the alphabet"
);

is_deeply(
  $config->get("/dir/file/alphabet"),
  [ qw(a b c d e f g h i j k l m n o p q r s t u v w x y z) ],
  "the alphabet"
);

is($config->get("/link_to_file"), undef, "symlink ignored");

is($config->get("/link_to_dir" ), undef, "symlink ignored");
