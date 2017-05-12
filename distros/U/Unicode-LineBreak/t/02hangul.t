use strict;
use Test::More;
require "t/lb.pl";

BEGIN { plan tests => 2 }

dotest('ko', 'ko.al', HangulAsAL => 'YES');
dotest('amitagyong', 'amitagyong');

1;

