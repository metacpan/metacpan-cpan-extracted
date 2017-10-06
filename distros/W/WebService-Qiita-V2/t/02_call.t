use strict;
use warnings;
use Test::More;
use Test::Fatal;

use WebService::Qiita::V2;

my $client = WebService::Qiita::V2->new;

like exception { $client->not_match_method }, qr/Can't locate object method "not_match_method" via package "WebService::Qiita::V2::Client::Methods"/;

my $user = $client->get_user('qiita');
is ref $user, "HASH";
ok scalar(keys(%$user)) > 0;

done_testing;
