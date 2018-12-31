use strict;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/..";
require "t/lb.pl";

BEGIN { plan tests => 2 }

dotest('ko', 'ko.al', HangulAsAL => 'YES');
dotest('amitagyong', 'amitagyong');

1;

