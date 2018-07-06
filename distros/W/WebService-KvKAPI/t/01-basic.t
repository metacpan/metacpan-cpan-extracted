use strict;
use warnings;
use Test::More 0.96;
use Test::Exception;

use WebService::KvKAPI;
use Sub::Override;
use Test::Mock::One;
use Test::Deep;

my $api = WebService::KvKAPI->new(
    api_key => 'foobar',
);

my @methods = qw(
    search
    profile
    api_call
    _build_open_api_client
);

foreach (@methods) {
    can_ok($api, $_);
}

my $client = $api->client;
isa_ok($client, "OpenAPI::Client");

my @openapi_operations = qw(
    Companies_GetCompaniesBasicV2
    Companies_GetCompaniesExtendedV2
);

foreach (@openapi_operations) {
    can_ok($client, $_);
}

my $override = Sub::Override->new(
    'OpenAPI::Client::WebService__KvKAPI_kvk_gsasearch_webapi__v1_json::Companies_GetCompaniesBasicV2' => sub {
        return Test::Mock::One->new(
            'X-Mock-Strict' => 1,
            error           => undef,
            res             => {
                json => \{
                    'foo' => 'bar',
                }
            },
        );
    },
);

my $answer = $api->api_call(
    'Companies_GetCompaniesBasicV2',
    { Bar => "baz" },
);

cmp_deeply($answer, { foo => 'bar' }, "Got the JSON response as a HashRef");

$override->replace(
    'OpenAPI::Client::WebService__KvKAPI_kvk_gsasearch_webapi__v1_json::Companies_GetCompaniesBasicV2' => sub {
        return Test::Mock::One->new(
            'X-Mock-Strict' => 1,
            error           => \{ message => 'Bad request' },
        );
    }
);

throws_ok(
    sub {
        $api->api_call('Companies_GetCompaniesBasicV2', { Bar => 'baz' });
    },
    qr/Error calling KvK API with operation 'Companies_GetCompaniesBasicV2': 'Bad request'/,
    "Error!"
);

sub mock_result {
    my $data = shift;
    $data->{items} //= [];
    $data = {
        nextLink  => 1,
        startPage => 1,
        totalItems => scalar @{$data->{items}},
        %$data,

    };

    Test::Mock::One->new(
        'X-Mock-Strict' => 1,
        error           => undef,
        res             => {
            json => \{
                data => $data,
            }
        },
    );
}

my @answers = (

    # search
    mock_result({ items => [] }),
    mock_result({ items => [qw(two items)]}),

    # search_all
    mock_result({ items => [qw(two items)] }),
    mock_result({ items => [qw(and three more)], nextLink => 0, startPage => 2}),

    # search_max
    mock_result({ items => [qw(two items)]}),
    mock_result({ items => [qw(and three more nah)], startPage => 2}),
    mock_result({ items => [qw(this makes nine)], nextLink => 0, startPage => 3}),

    # search_max: items max reached
    mock_result({ items => [qw(one)]}),
    mock_result({ items => [qw(and)], startPage => 2}),
    mock_result({ items => [qw(this makes five)], startPage => 3}),
    # search_max: this isn't reached until
    mock_result({ items => [qw(and)], nextLink => 1, startPage => 4}),
    mock_result({ items => [qw(many)], nextLink => 0, startPage => 4}),
);

$override->replace(
    'OpenAPI::Client::WebService__KvKAPI_kvk_gsasearch_webapi__v1_json::Companies_GetCompaniesBasicV2' => sub {
        return shift @answers;
    }
);

{
    my $items = $api->search(foo => 'bar');
    cmp_deeply($items, [], "Empty search");
}

{
    my $items = $api->search(foo => 'bar');
    cmp_deeply($items, [qw(two items)], "Search finds two");
}

{
    my $items = $api->search_all(foo => 'bar');
    cmp_deeply($items, [qw(two items and three more)], "search_all finds them all");
}

{
    my $items = $api->search_max(3, foo => 'bar');
    cmp_deeply($items, [qw(two items and three more nah)], "search_max finds them all");
    shift @answers; # clear the answers
}

{
    my $items = $api->search_max(3, foo => 'bar');
    cmp_deeply($items, [qw(one and this makes five)], "search_max finds them all: within 3");
}

{
    my $items = $api->search_max(3, foo => 'bar');
    cmp_deeply($items, [qw(and many)], "search_max finds them all: within 3");
}


@answers = (

    # profile: fails
    mock_result({ items => [] }),
    mock_result({ items => [qw(also dies)] }),

    # profile: working solution
    mock_result({ items => [{ my => 'company'}] }),
);

$override->replace(
    'OpenAPI::Client::WebService__KvKAPI_kvk_gsasearch_webapi__v1_json::Companies_GetCompaniesExtendedV2' => sub {
        return shift @answers;
    }
);

throws_ok(
    sub {
        $api->profile(foo => 'bar');
    },
    qr/Unable to find company you where looking for\!/,
    "Unable to get results from ->profile: zero results"
);

throws_ok(
    sub {
        $api->profile(foo => 'bar');
    },
    qr/Unable to find company you where looking for\!/,
    "Unable to get results from ->profile: two or more results"
);

my $company = $api->profile(foo => 'bar');
cmp_deeply($company, {my => 'company'}, "We have extended information about the company");

done_testing;
