use strict;
use warnings;
use Test::More;

use WebService::Qiita::V2;

my $client = WebService::Qiita::V2->new;

is $client->{team}, undef;

$client->get_authenticated_user;
is $client->get_error->{url}, 'https://qiita.com/api/v2/authenticated_user';

$client->{team} = 'qiita_team';
$client->get_authenticated_user;
is $client->get_error->{url}, 'https://qiita_team.qiita.com/api/v2/authenticated_user';

done_testing;
