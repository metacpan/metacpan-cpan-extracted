use Test::More tests => 1;

use strict;
use warnings;
use WWW::Shorten 'GitHub';

my $url = 'https://github.com/LoonyPandora/WWW-Shorten-GitHub';

is(makeashorterlink($url), 'http://git.io/2BUFew');
