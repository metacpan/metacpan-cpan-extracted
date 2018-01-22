use strict;
use warnings;
use Test::More;

use WebService::BitFlyer;

my $bf = WebService::BitFlyer->new(
    access_key => 'YOUR_ACCESS_KEY',
    secret_key => 'YOUR_SECRET_KEY',
);

isa_ok $bf, 'WebService::BitFlyer';

isa_ok $bf->api, 'WebService::BitFlyer::API';

done_testing;
