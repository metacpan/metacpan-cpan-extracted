
use Test::More tests => 1;

use strict;
use WebService::BuzzurlAPI;

my $buzz = WebService::BuzzurlAPI->new;

my $res = $buzz->url_info(url => "http://buzzurl.jp/");
ok($res->is_success);

