package Test::TCM::Role::API;

=head1 NAME

Test::TCM::Role::API - Role to test PSGI-based JSON API using
L<Test::Class::Moose>.

=head1 SYNOPSIS

    package TestsFor::MyApp::Controller::API::v1::Some::Thing

    use Test::Class::Moose;
    with qw(
        Test::TCM::Role::API
    );

    sub _api_route_prefix { '/api/v1' }

    sub test_some_route ($test, $) {

        # Calls "GET /api/v1/character"
        $test->api_ok(
            'List characters',
            [GET => '/character'],
            {
                status       => HTTP_OK,
                json_content => {
                    superhashof(
                        {
                            attributes =>
                              { map { $_ => ignore() } qw(id name created) },
                        }
                    )
                },
            }
        );

        $test->api_ok(
            'Create character',
            [
                POST => '/character' => {
                    name    => 'Player 1',
                    user_id => 12345,
                }
            ],
            {
                status       => HTTP_OK,
                json_content => { success => 1 },
            }
        );
    }

=cut

use Moose::Role;

use v5.20;
use warnings;
use experimental qw(smartmatch signatures);

use Carp qw(croak);
use HTTP::Request;
use JSON qw(encode_json);
use Plack::Test;
use Test::Deep qw(cmp_deeply);
use Test::Differences qw(eq_or_diff);
use Test::More;

our $VERSION = 0.02;

=head1 REQUIRED METHODS

=head2 psgi_app

PSGI application we're testing.

=cut

requires 'psgi_app';

=head1 ATTRIBUTES

=head2 api_client

PSGI-compatible API client to use. Built automatically using C<psgi_app> method.

=cut

has 'api_client' => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    builder => '_build_api_client',
);

sub _build_api_client {
    my ($test) = @_;
    return Plack::Test->create($test->psgi_app);
}

after test_setup => sub ( $test, $ ) {
    $test->api_client->add_header( $test->_api_headers );
};

=head1 PRIVATE METHODS THAT CAN BE OVERRIDDEN

=head2 _api_content_type

Returns content type for this API, default: C<application/vnd.api+json>.

=cut

sub _api_content_type {'application/vnd.api+json'}

=head2 _api_headers

Returns a hash of headers to add to C<< $test->mech >>, defaults to
C<< ( Accept => _api_content_type() ) >>

=cut

sub _api_headers {
    return ( 'Accept' => _api_content_type() );
}

=head2 _api_route_prefix

Common prefix for all API requests. Defaults to the empty string.

=cut

sub _api_route_prefix {''}

=head2 _before_request_hook($request)

Method that is called right before request is made. Gets a complete
HTTP::Request object as the only argument. You can inspect / modify this
request as needed - e.g. to add additional authorization headers to it.

=head1 METHODS

=head2 api_ok($title, \@request_args, \%expected)

    In: $title - (sub)test title
        \@request_args - request data, 3-elements array of:
            $method - HTTP method
            $route - route to call
            \%params - URL query params (for GET) or JSON data (for other
            request types)
        \%expected - hash of expected parameters with the following fields
            status - HTTP status code; defaults to any successful code
            json_content - reference to a structure we expect, to be passed to
            C<Test::Deep::cmp_deeply> (so C<Test::Deep>'s functions can be used
            to skip / ignore some methods in it).

Perform API C<$method> request on the C<$route> and test its output against
C<%expected> values.

If C<_api_route_prefix()> is implemented in the consuming class, the value it
returns gets prepended to the route before request is performed.

=cut

sub api_ok ( $test, $title, $request_args, $expected ) {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $test->_perform_request($test->_generate_request(@$request_args));
    $test->_process_test_results( $title, $expected );
}

sub _generate_request ($test, $method, $route, $params = undef) {
    if ( my $route_prefix = $test->_api_route_prefix // '' ) {
        $route = $route_prefix . $route;
    }

    my $request = HTTP::Request->new( $method => $route );
    $request->header( map { $_ => _api_content_type() }
          qw(Accept Content-Type) );
    given ($method) {
        when ( [qw(GET DELETE)] ) {
            if ($params) {
                $request->uri->query_form($params);
            }
        }
        when ( [qw(PATCH POST PUT)] ) {
            if ($params) {
                $request->content( encode_json($params) );
            }
        }
        default {
            croak "Don't know such request method as '$method'";
        }
    }

    return $request;
}

sub _perform_request ($test, $request) {
    if ($test->can('_before_request_hook')) {
        $test->_before_request_hook($request);
    }
    $test->api_client->request($request);
}

sub _process_test_results ( $test, $title, $expected ) {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    subtest $title => sub {

        if ( exists $expected->{status} ) {
            is( $test->api_client->status, $expected->{status},
                "Status is as expected ($expected->{status})"
            );
        }
        else {
            like(
                $test->api_client->status, qr/^2\d{2}$/,
                'Status is success'
            );
        }

        if ( exists $expected->{json_content} ) {
            if ( my $json_content = eval {
                decode_json($test->api_client->content);
            } )
            {
                # eq_or_diff() is only used to output diagnostics in case of a
                # test failure.
                my $ok = cmp_deeply(
                    $json_content,
                    $expected->{json_content},
                ) or eq_or_diff($json_content, $expected->{json_content});
            }
            else {
                fail("We've got a proper JSON response");
                diag( 'Got: ' . $test->api_client->response->as_string );
            }
        }
    };
}

=head1 AUTHOR

Ilya Chesnokov L<chesnokov@cpan.org>.

=head1 LICENSE

Under the same terms as Perl itself.

=head1 CREDITS

Many thanks to the following people and organizations:

=over

=item Sam Kington L<cpan@illuminated.co.uk>

For the idea and the initial implementation.

=item All Around the World SASU L<https://allaroundtheworld.fr>

For sponsoring this rewrite and publication.

=back

=cut

1;
