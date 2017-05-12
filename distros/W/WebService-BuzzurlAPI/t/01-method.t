
use Test::More tests => 2;

use strict;
use WebService::BuzzurlAPI;

my $buzz = WebService::BuzzurlAPI->new;

# accessor method
can_ok($buzz, qw(email password));

# request method
can_ok($buzz, qw(url_info readers favorites user_articles recent_articles bookmark_count add));

