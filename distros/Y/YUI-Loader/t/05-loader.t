use strict;
use warnings;

use Test::More;
use Test::Deep;
plan qw/no_plan/;

use YUI::Loader;
use Directory::Scratch;
my $scratch = Directory::Scratch->new;
my $base = $scratch->base;
sub file { return $base->file(@_) }

my $loader = YUI::Loader->new_from_yui_host(cache => $base);
ok($loader);
SKIP: {
    $ENV{TEST_YUI_HOST} or skip "Not testing going out to the yui host";
    is($loader->file("yuitest"), file "yuitest.js");
}
$loader->filter_min;
SKIP: {
    $ENV{TEST_YUI_HOST} or skip "Not testing going out to the yui host";
    is($loader->file("yuitest"), file "yuitest-min.js");
}
is($loader->item_path("yuitest"), "yuitest/yuitest-min.js");
is($loader->item_file("yuitest"), "yuitest-min.js");

ok(YUI::Loader->new_from_yui_host);
ok(YUI::Loader->new_from_yui_dir(base => "./"));
ok(YUI::Loader->new_from_uri(base => "./"));
ok(YUI::Loader->new_from_dir(base => "./"));

ok(YUI::Loader->new_from_yui_dir(dir => "./"));
ok(YUI::Loader->new_from_dir(dir => "./"));

is(YUI::Loader->new_from_yui_dir(dir => "./yui/\%v/build")->source->base, "yui/2.8.1/build");

