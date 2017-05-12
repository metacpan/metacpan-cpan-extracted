
use Test::More tests => 1;

use strict;
use WebService::BuzzurlAPI;

my $buzz = WebService::BuzzurlAPI->new;
my $res = $buzz->recent_articles( num => 1, of => 0, threshold => 0 );
ok($res->is_success);

