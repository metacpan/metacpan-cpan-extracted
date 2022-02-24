use Test::More;
use Test::Deep;

use WebService::KvKAPI::LocationProfile;
use Test::Mock::One;

my $client = WebService::KvKAPI::LocationProfile->new(
    api_key => 'testsuite'
);

my $operation;
my %args;

use Sub::Override;
my $override = Sub::Override->new(
    'WebService::KvKAPI::LocationProfile::api_call' => sub {
        shift;
        $operation = shift;
        %args = @_;
        return { foo => 'bar' };
    }
);

my $res = $client->get_location_profile(1234567);
cmp_deeply($res, { foo => 'bar' }, "Got the results from the KvK API");
is($operation, 'getVestigingByVestigingsnummer', ".. with the correct operation");
cmp_deeply(\%args, { vestigingsnummer => '000001234567' }, ".. and the correct arguments");

done_testing;
