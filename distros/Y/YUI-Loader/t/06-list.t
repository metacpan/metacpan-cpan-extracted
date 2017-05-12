use strict;
use warnings;

use Test::More;
use Test::Deep;
plan qw/no_plan/;

use YUI::Loader;

my $loader = YUI::Loader->new_from_yui_host(cache => "t.tmp");
ok($loader->list);

cmp_deeply([ $loader->list->name ], []);

$loader->include->yuitest;
cmp_deeply([ $loader->list->name ], [qw{ logger-skin yuitest-skin yahoo dom event logger yuitest }]);
cmp_deeply([ map { "$_" } $loader->list->item_path ], [qw{ logger/assets/skins/sam/logger.css yuitest/assets/skins/sam/yuitest.css yahoo/yahoo.js dom/dom.js event/event.js logger/logger.js yuitest/yuitest.js }]);

$loader->clear;
$loader->include->imagecropper;
cmp_deeply([ $loader->list->name ], [qw{ resize-skin imagecropper-skin yahoo dom event dragdrop element resize imagecropper }]);
cmp_deeply([ map { "$_" } $loader->list->item_path ],
    [qw{ resize/assets/skins/sam/resize.css imagecropper/assets/skins/sam/imagecropper.css yahoo/yahoo.js dom/dom.js event/event.js dragdrop/dragdrop.js element/element.js resize/resize.js imagecropper/imagecropper.js }]);
