use Test::More;
use Sub::Override;
use Test::Deep;
use Test::Mock::One;

use WebService::KvKAPI::Search;

sub get_openapi_client {
    my %args = @_;
    $args{api_key} //= 'testsuite';
    return WebService::KvKAPI::Search->new(%args);
}

my $client = get_openapi_client();

my $operation;
my %args;

use Sub::Override;
my $override = Sub::Override->new(
    'WebService::KvKAPI::Search::api_call' => sub {
        shift;
        $operation = shift;
        %args = @_;
        return { foo => 'bar' };
    }
);

my $res = $client->search(
    kvkNummer        => 1234567,
    rsin             => 9,
    vestigingsnummer => 12,
);

cmp_deeply($res, { foo => 'bar' }, "Got the results from the KvK API");

cmp_deeply(
    \%args,
    {
        kvkNummer        => '01234567',
        rsin             => '000000009',
        vestigingsnummer => '000000000012',
    },
    "Mangled numbers correctly correctly"
);

done_testing;
