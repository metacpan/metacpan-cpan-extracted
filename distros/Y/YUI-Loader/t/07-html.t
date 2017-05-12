use strict;
use warnings;

use Test::More;
use Test::Deep;
plan qw/no_plan/;
use Directory::Scratch;
my $scratch = Directory::Scratch->new;
my $base = $scratch->base;
sub file { return $base->file(@_) }

use YUI::Loader;

my $loader = YUI::Loader->new_from_yui_host;
$loader->include->yuitest->reset->fonts->base;
is($loader->html."\n", <<_END_);
<link rel="stylesheet" href="http://yui.yahooapis.com/2.8.1/build/reset/reset.css" type="text/css"/>
<link rel="stylesheet" href="http://yui.yahooapis.com/2.8.1/build/fonts/fonts.css" type="text/css"/>
<link rel="stylesheet" href="http://yui.yahooapis.com/2.8.1/build/base/base.css" type="text/css"/>
<link rel="stylesheet" href="http://yui.yahooapis.com/2.8.1/build/logger/assets/skins/sam/logger.css" type="text/css"/>
<link rel="stylesheet" href="http://yui.yahooapis.com/2.8.1/build/yuitest/assets/skins/sam/yuitest.css" type="text/css"/>
<script src="http://yui.yahooapis.com/2.8.1/build/yahoo/yahoo.js" type="text/javascript"></script>
<script src="http://yui.yahooapis.com/2.8.1/build/dom/dom.js" type="text/javascript"></script>
<script src="http://yui.yahooapis.com/2.8.1/build/event/event.js" type="text/javascript"></script>
<script src="http://yui.yahooapis.com/2.8.1/build/logger/logger.js" type="text/javascript"></script>
<script src="http://yui.yahooapis.com/2.8.1/build/yuitest/yuitest.js" type="text/javascript"></script>
_END_

SKIP: {
    $ENV{TEST_YUI_HOST} or skip "Not testing going out to the yui host";
    my $loader = YUI::Loader->new_from_yui_host(cache => { uri => "http://example.com/assets", dir => $base->subdir("htdocs/assets") });
    $loader->include->yuitest->reset->fonts->base;
    is($loader->html."\n", <<_END_);
<link rel="stylesheet" href="http://example.com/assets/reset.css" type="text/css"/>
<link rel="stylesheet" href="http://example.com/assets/fonts.css" type="text/css"/>
<link rel="stylesheet" href="http://example.com/assets/base.css" type="text/css"/>
<link rel="stylesheet" href="http://example.com/assets/logger.css" type="text/css"/>
<link rel="stylesheet" href="http://example.com/assets/yuitest.css" type="text/css"/>
<script src="http://example.com/assets/yahoo.js" type="text/javascript"></script>
<script src="http://example.com/assets/dom.js" type="text/javascript"></script>
<script src="http://example.com/assets/event.js" type="text/javascript"></script>
<script src="http://example.com/assets/logger.js" type="text/javascript"></script>
<script src="http://example.com/assets/yuitest.js" type="text/javascript"></script>
_END_
    ok(-s $base->file(qw/htdocs assets reset.css/));
    ok(-s $base->file(qw/htdocs assets yuitest.js/));
}
