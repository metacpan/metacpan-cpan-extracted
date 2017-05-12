
use Test::More tests => 1;

use strict;
use WebService::BuzzurlAPI;

my $buzz = WebService::BuzzurlAPI->new;
my $res = $buzz->bookmark_count( url => "http://buzzurl.jp" );
ok($res->is_success);

