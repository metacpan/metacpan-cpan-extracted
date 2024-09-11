use strict;
use warnings;
use Test::More;
use Test::MockModule;
use Log::Any::Test;
use Log::Any qw($log);
use WebService::GrowthBook::FeatureRepository;

my $mock = Test::MockModule->new('HTTP::Tiny');
my @args;
my $get_result;
$mock->mock(
    'get',
    sub {
        shift;
        @args = @_;
        return $get_result;
    }
);

my $repo =
  WebService::GrowthBook::FeatureRepository->new( client_key => 'key' );
for my $status ( 400, 401, 402 ) {
    $get_result = { status => 400 };
    my $result = $repo->load_features( "http://example.com", "akey" );
    ok( !defined($result), "get undef since status is greater than 400" );
    $log->contains_ok( qr/Failed to fetch features, received status code/,
        "log contains status code" );
}
is_deeply(
    \@args,
    [
        'http://example.com/api/features/akey',
        {
            'headers' => {
                'Content-Type'  => 'application/json'
            }
        }
    ]
);

$get_result = { status => 200, content => '' };
$log->clear;
my $result = $repo->load_features( "http://example.com", "a key" );
$log->contains_ok( qr/GrowthBook API response missing features/, "warn ok" );
ok( !defined($result), "get undef since missing feature" );
$log->clear;
$get_result = { status => 200, content => '{"featur' };
$result     = $repo->load_features( "http://example.com", "a key" );
$log->contains_ok( qr/Failed to decode feature JSON from GrowthBook API/,
    "warn ok" );
ok( !defined($result), "get undef since missing feature" );
$get_result = {
    status  => 200,
    content =>
'{"features":[{"id":"bool-feature","defaultValue":"true","valueType":"boolean"}]}'
};
$result = $repo->load_features( "http://example.com", "a key" );
is_deeply(
    $result,
    [
        {
            'valueType'    => 'boolean',
            'defaultValue' => 'true',
            'id'           => 'bool-feature'
        }
    ],
    "got correct result"
);
done_testing();
