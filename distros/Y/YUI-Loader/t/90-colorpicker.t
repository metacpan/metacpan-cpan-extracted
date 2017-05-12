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
$loader->include->colorpicker;
is($loader->html."\n", <<_END_);
<link rel="stylesheet" href="http://yui.yahooapis.com/2.8.1/build/colorpicker/assets/skins/sam/colorpicker.css" type="text/css"/>
<script src="http://yui.yahooapis.com/2.8.1/build/yahoo/yahoo.js" type="text/javascript"></script>
<script src="http://yui.yahooapis.com/2.8.1/build/dom/dom.js" type="text/javascript"></script>
<script src="http://yui.yahooapis.com/2.8.1/build/event/event.js" type="text/javascript"></script>
<script src="http://yui.yahooapis.com/2.8.1/build/dragdrop/dragdrop.js" type="text/javascript"></script>
<script src="http://yui.yahooapis.com/2.8.1/build/element/element.js" type="text/javascript"></script>
<script src="http://yui.yahooapis.com/2.8.1/build/slider/slider.js" type="text/javascript"></script>
<script src="http://yui.yahooapis.com/2.8.1/build/colorpicker/colorpicker.js" type="text/javascript"></script>
_END_

