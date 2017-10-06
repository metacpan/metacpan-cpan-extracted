use strict;
use warnings;
use Test::More;

use WebService::Qiita::V2;

ok my $client = WebService::Qiita::V2->new;
isa_ok $client, 'WebService::Qiita::V2::Client';

done_testing;
