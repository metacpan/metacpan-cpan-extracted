use Test2::V0;

use WebService::Readwise;

die 'You need to set WEBSERVICE_READWISE_TOKEN' unless $ENV{WEBSERVICE_READWISE_TOKEN};

my $sr = WebService::Readwise->new;

my $result = $sr->auth;

is $result, 204, 'Basic check of token gives a 204';


done_testing;