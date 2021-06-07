
=head1 DESCRIPTION

This tests the Zapp::Task::GetOAuth2Token class.

=cut

use Mojo::Base -strict, -signatures;
use Test::Zapp;
use Test::More;
use Mojo::JSON qw( decode_json encode_json false true );
use Mojo::Util qw( b64_decode );

my $t = Test::Zapp->new;

my $last_request;
# Add some test endpoints
$t->app->routes->post( '/test/success' )
  ->to( cb => sub( $c ) {
    # XXX: HTTP Basic auth: base64( url_encode( <client_id> ) . ':' . url_encode( <client_secret> ) )
    # XXX: $c->param( 'client_id' ); $c->param( 'client_secret' );
    $last_request = $c->tx->req;
    return $c->render(
        status => 200,
        json => {
            access_token => 'TESTACCESSTOKEN',
            token_type => 'bearer',
            expires_in => 3600,
            scope => $c->param( 'scope' ),
        },
    );
  } );
$t->app->routes->post( '/test/failure' )
  ->to( cb => sub( $c ) {
    $last_request = $c->tx->req;
    return $c->render(
        status => 400,
        json => {
            error => 'invalid_scope',
            error_description => 'You gave an invalid scope.',
        },
    );
  } );

subtest 'run' => sub {
    subtest 'success' => sub {
        $t->run_task(
            'Zapp::Task::GetOAuth2Token' => {
                endpoint => $t->ua->server->url->path( '/test/success' )->to_abs,
                scope => 'create',
                client_id => '<client_id>',
                client_secret => '<client_secret>',
            },
            'Test: Success',
        );
        $t->task_info_is( state => 'finished', 'job finished' );
        $t->task_output_is( {
            is_success => true,
            access_token => 'TESTACCESSTOKEN',
            token_type => 'bearer',
            expires_in => 3600,
            scope => 'create',
            refresh_token => undef,
        });

        ok $last_request, 'mock token request handler called';
        is $last_request->param( 'scope' ), 'create',
            'scope passed in query param';
        is $last_request->param( 'grant_type' ), 'client_credentials',
            'grant_type passed in query param';

        my ( $auth ) = $last_request->headers->authorization =~ m{Basic (\S+)};
        my ( $got_client_id, $got_client_secret ) = split /:/, b64_decode( $auth );
        is $got_client_id, '<client_id>',
            'client_id is "username" in HTTP Authorization header';
        is $got_client_secret, '<client_secret>',
            'client_secret is "password" in HTTP Authorization header';
    };

    subtest 'failure' => sub {
        $t->run_task(
            'Zapp::Task::GetOAuth2Token' => {
                endpoint => $t->ua->server->url->path( '/test/failure' )->to_abs,
                scope => 'create',
                client_id => '<client_id>',
                client_secret => '<client_secret>',
            },
            'Test: Failure',
        );
        $t->task_info_is( state => 'failed', 'job failed' );
        $t->task_output_is( {
            is_success => false,
            error => 'invalid_scope',
            error_description => 'You gave an invalid scope.',
            error_uri => undef,
        });

        ok $last_request, 'mock token request handler called';
        is $last_request->param( 'scope' ), 'create',
            'scope passed in query param';
        is $last_request->param( 'grant_type' ), 'client_credentials',
            'grant_type passed in query param';

        my ( $auth ) = $last_request->headers->authorization =~ m{Basic (\S+)};
        my ( $got_client_id, $got_client_secret ) = split /:/, b64_decode( $auth );
        is $got_client_id, '<client_id>',
            'client_id is "username" in HTTP Authorization header';
        is $got_client_secret, '<client_secret>',
            'client_secret is "password" in HTTP Authorization header';
    };
};

done_testing;

