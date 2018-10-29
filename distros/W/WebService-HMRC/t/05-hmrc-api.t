#!perl -T
use strict;
use warnings;
use Test::More;
use WebService::HMRC::Request;

plan tests => 12;

my ($r, $response);

=pod

This tests GET requests to the HMRC MTDfB sandbox API using
the test L<Hello World API|https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/api-example-microservice/1.0>.

Only GET requests are tested as this test API does not provide an
endpoint accepting POST requests

To run these tests:

=over

=item * An application must be registered with HMRC

=item * The application must be enabled for the Hello World API

=item * HMRC_SERVER_TOKEN environment variable must be set

=item * HMRC_AUTH_CODE environment variable must be set

=item * The HMRC sandbox test api endpoints must be functioning

=back

=cut

SKIP: {
    my $skip_count = 12;
    my $server_token = $ENV{HMRC_SERVER_TOKEN} or skip (
        'environment variable HMRC_SERVER_TOKEN is not set',
        $skip_count,
    );
    my $authorisation_code = $ENV{HMRC_AUTH_CODE} or skip (
        'environment variable HMRC_AUTH_CODE is not set',
        $skip_count,
    );

    isa_ok(
        $r = WebService::HMRC::Request->new(),
        'WebService::HMRC::Request',
        'Created WebService::HMRC::Request object'
    );


    # get from open endpoint
    isa_ok(
        $response = $r->get_endpoint({
            endpoint => '/hello/world',
        }),
        'WebService::HMRC::Response',
        'Querying /hello/world endpoint yielded response object'
    );
    ok($response->is_success, 'Querying /hello/world endpoint successful');
    is($response->data->{message}, 'Hello World', '/hello/world endpoint returns expected message');


    # get from application-restricted endpoint
    ok($r->auth->server_token($server_token), 'set client_id');
    isa_ok(
        $response = $r->get_endpoint({
            endpoint => '/hello/application',
            auth_type => 'application',
        }),
        'WebService::HMRC::Response',
        'Querying /hello/application endpoint yielded response object'
    );

    ok($response->is_success, 'Querying /hello/application endpoint successful');
    is($response->data->{message}, 'Hello Application', '/hello/application endpoint returns expected message');

   
    # get from user-restricted endpoint
    ok($r->auth->access_token($authorisation_code), 'set access_token');
    isa_ok(
        $response = $r->get_endpoint({
            endpoint => '/hello/user',
            auth_type => 'user',
        }),
        'WebService::HMRC::Response',
        'Querying /hello/user endpoint yielded response object'
    );
    ok($response->is_success, 'Querying /hello/user endpoint successful');
    is($response->data->{message}, 'Hello User', '/hello/user endpoint returns expected message');
}
