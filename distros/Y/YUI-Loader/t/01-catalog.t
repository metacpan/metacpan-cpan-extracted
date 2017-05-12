use strict;
use warnings;

use Test::More;
use Test::Deep;
plan qw/no_plan/;

use YUI::Loader::Catalog;

my $catalog = YUI::Loader::Catalog->new;
ok($catalog);

cmp_deeply([ $catalog->name_list ], superbagof(qw/reset base container containercore yuitest/));
ok($catalog->entry("yuitest"));

is($catalog->entry("yuitest")->file, "yuitest.js");
is($catalog->entry("imagecropper")->file, "imagecropper.js");

is($catalog->item([qw/yuitest/])->file, "yuitest.js");
is($catalog->item([qw/yuitest min/])->file, "yuitest-min.js");
is($catalog->item([qw/yuitest debug/])->file, "yuitest-debug.js");
is($catalog->item([qw/imagecropper/])->file, "imagecropper.js");
is($catalog->item([qw/imagecropper min/])->file, "imagecropper-min.js");
is($catalog->item([qw/imagecropper debug/])->file, "imagecropper-debug.js");
