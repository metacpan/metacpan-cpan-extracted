use Test::More tests => 2;

use strict;
use warnings;
use WWW::Shorten 'GitHub';

my $url = 'https://github.com/LoonyPandora/WWW-Shorten-GitHub';

is(makealongerlink('https://git.io/2BUFew'), $url);
is(makealongerlink('2BUFew'), $url);
