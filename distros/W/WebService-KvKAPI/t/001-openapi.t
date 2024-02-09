use Test::More;
use Test::Deep;
use Test::Exception;
use Test::Mock::One;
use Sub::Override;

# TODO: Make a specific test class for this
use WebService::KvKAPI::BasicProfile;

sub get_openapi_client {
    my %args = @_;
    $args{api_key} //= 'foobar';
    my $profile = WebService::KvKAPI::BasicProfile->new(%args);

    my $client = $profile->client;
    isa_ok($client, "OpenAPI::Client");

    return $client;
}

my $client = get_openapi_client;

my $base_uri  = 'https://api.kvk.nl/api';
my $base_host = 'api.kvk.nl';

is($client->base_url, $base_uri, "Base URI is: $base_uri");
is($client->base_url->host, $base_host, ".. and the base host is '$base_host'");

{   # URI mangling
    my $client = get_openapi_client(api_host => 'foo.bar');

    my $base_uri  = 'https://foo.bar/api';
    my $base_host = 'foo.bar';

    is($client->base_url, $base_uri, "Base URI is: $base_uri");
    is($client->base_url->host, $base_host, ".. and the base host is '$base_host'");

}
{
    my $client = get_openapi_client(api_host => 'foo.bar', api_path => '/foo/api');
    my $base_uri  = 'https://foo.bar/foo/api';
    my $base_host = 'foo.bar';

    is($client->base_url, $base_uri, "Base URI is: $base_uri");
    is($client->base_url->host, $base_host, ".. and the base host is '$base_host'");
    is($client->base_url->path, '/foo/api', ".. and the base path is '/foo/api'");
}

{ # Spoof mode
    my $client = get_openapi_client(spoof => 1);
    my $base_uri  = 'https://api.kvk.nl/test/api';
    my $base_host = 'api.kvk.nl';

    is($client->base_url, $base_uri, "Spoof mode base URI is: $base_uri");
    is($client->base_url->host, $base_host, ".. and the base host is '$base_host'");

}

{

    my $client = WebService::KvKAPI::BasicProfile->new(api_key => 'foo');
    my $override = Sub::Override->new(
        'OpenAPI::Client::WebService__KvKAPI__BasicProfile_kvkapi_yml::getBasisprofielByKvkNummer' => sub {
            my $client = shift;
            $args = shift;
            return Test::Mock::One->new(
                'X-Mock-Strict' => 1,
                error           => undef,
                res             => {
                    json => \{
                        'foo' => 'bar',
                    }
                },
            );
        }
    );

    my $res = $client->get_basic_profile(1234567);
    is(ref $args, 'HASH', "Called the OpenAPI client with arguments");
    cmp_deeply($res, { foo => 'bar' }, ".. and parsed the result correctly");

    $override->replace(
        'OpenAPI::Client::WebService__KvKAPI__BasicProfile_kvkapi_yml::getBasisprofielByKvkNummer'
            => sub {
            my $client = shift;
            $args = shift;
            return Test::Mock::One->new(
                'X-Mock-Strict' => 1,
                error           => \{ message => 'Bad Request' },
                res             => { code => 401, },
                result          => { body => 'foo', },
            );
        }
    );

    throws_ok(
        sub {
            $client->get_basic_profile(1234567);
        },
        qr/Error calling KvK API with operation 'getBasisprofielByKvkNummer': 'foo' \(Bad Request\)/,
        "Failure while calling KvK API"
    );

    $override->replace(
        'OpenAPI::Client::WebService__KvKAPI__BasicProfile_kvkapi_yml::getBasisprofielByKvkNummer'
            => sub {
            my $client = shift;
            $args = shift;
            return Test::Mock::One->new(
                'X-Mock-Strict' => 1,
                error           => \{ message => 'Bad Request' },
                res             => { code => 404, },
                result          => { body => 'foo', },
            );
        }
    );

    lives_ok(
        sub {
            my $res = $client->get_basic_profile(1234567);
            is($res, undef, "Not found");
        },
        "Calling something that does not exist"
    );

    $override->replace('OpenAPI::Client::call' => sub { die "call failed" });
    throws_ok(
        sub {
            $client->get_basic_profile(1234567);
        },
        qr/Died calling KvK API with operation 'getBasisprofielByKvkNummer': call failed/,
        "Died during client->call",
    );

}

done_testing;
