use strict;
use utf8;
use warnings;

use Test::More;
use Test::Exception;

use WebService::IPAPI;

my ($ipapi, $api_key) = ('', '1xxxxxxxxxxxxxxxxxxxxxxxxxxxxx32');

$ipapi = WebService::IPAPI->new(api_key => $api_key);
is($ipapi->api_url, 'http://api.ipapi.com/api/', 'expect API URL match');
is($ipapi->api_key, $api_key, 'expect api key match');

foreach my $plan (qw(standard business business_pro)) {
    $ipapi = WebService::IPAPI->new(api_key => $api_key, api_plan => $plan);
    is($ipapi->api_url, 'https://api.ipapi.com/api/', qq|expect API URL match for $plan plan|);
}

dies_ok {
    $ipapi = WebService::IPAPI->new(api_key => 'foobar');
} 'expect termination on invalid API key length';

done_testing;
