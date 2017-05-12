use strict;
use warnings;

use File::Spec;

use Test::More;

use XML::Tiny::Tree;

# ------------------

my($count)      = 0;
my($input_file) = File::Spec -> catfile('data', 'test.xml');
my($tree)       = XML::Tiny::Tree -> new(input_file => $input_file) -> convert;
my($tag)        = $tree -> value;
my($meta)       = $tree -> meta;

diag "Processing $input_file";

ok($tag eq 'tag_1', 'Root tag name (tag_1)'); $count++;

my(@children)   = $tree -> children;
$tag            = $children[0] -> value;
$meta           = $children[0] -> meta;
my($attr_value) = $$meta{attributes}{attr_2_name};

ok($tag        eq 'tag_2',        'First child tag name (tag_2)');          $count++;
ok($attr_value eq 'attr_2_value', 'First child attr value (attr_2_value)'); $count++;

@children = $children[1] -> children;

$tag        = $children[0] -> value;
$meta       = $children[0] -> meta;
$attr_value = $$meta{attributes}{attr_4_name_1};

ok($tag        eq 'tag_4',        "Second child's first child tag name (tag_4)");              $count++;
ok($attr_value eq 'attr_4_value_1', "Second child's first child attr value (attr_4_value_1)"); $count++;

done_testing($count);
