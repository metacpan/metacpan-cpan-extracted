use strict;
use utf8;
use warnings;

use Test::More;
use WebService::Mocean;

BEGIN {
    if (!defined $ENV{MOCEAN_API_KEY} and !defined $ENV{MOCEAN_API_SECRET}) {
        plan skip_all => '$ENV{MOCEAN_API_KEY} and $ENV{MOCEAN_API_SECRET} not set, skipping live tests'
    }
}

my ($got, $expect, $params) = ('', '', {});

my $api_key = $ENV{MOCEAN_API_KEY};
my $api_secret = $ENV{MOCEAN_API_SECRET};
my $mocean_api = WebService::Mocean->new(api_key => $api_key, api_secret => $api_secret);

$params = {
    'mocean-to' => 1,
    'mocean-brand' => 1
};

$got = $mocean_api->sms->send_verification_code($params);
is($got->{status}, 1, 'expect error');

done_testing;
