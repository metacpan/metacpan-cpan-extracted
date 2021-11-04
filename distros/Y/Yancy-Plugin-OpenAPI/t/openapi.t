
=head1 DESCRIPTION

This tests the OpenAPI plugin:

* Generating the OpenAPI spec from a Yancy schema
* Generating routes for the OpenAPI spec

=cut

use Test::Mojo;
use Mojo::JSON qw( true false );
use Test::More;

my $t = Test::Mojo->new( 'Mojolicious' );
$t->app->plugin( Yancy => {
  backend => 'memory://',
  schema => {
    users => {
      'x-id-field' => 'user_id',
      required => [qw( username )],
      properties => {
        user_id => {
          type => 'integer',
          readOnly => true,
        },
        username => {
          type => 'string',
        },
        email => {
          type => 'string',
        },
      },
    },
  },
});

subtest 'generate openapi spec' => sub {
  $t->app->yancy->plugin( 'OpenAPI', { route => '/schema' } );
  $t->get_ok( '/schema' )->status_is( 200 )
    ->json_has( '/definitions' )
    ->json_has( '/definitions/_Error' )
    ->json_is( '/definitions/users/type' => 'object' )
    ->json_is( '/definitions/users/x-id-field' => 'user_id' )
    ;

  my %to = (
    controller => 'yancy',
    schema => 'users',
    format => 'json',
  );
  $t->json_has( '/paths/~1users/get' )
    ->json_is( '/paths/~1users/get/x-mojo-to', { %to, action => 'list' } )
    ->json_has( '/paths/~1users/post' )
    ->json_is( '/paths/~1users/post/x-mojo-to', { %to, action => 'set' } )
    ->json_has( '/paths/~1users~1{user_id}/get' )
    ->json_is( '/paths/~1users~1{user_id}/get/x-mojo-to', { %to, action => 'get' } )
    ->json_has( '/paths/~1users~1{user_id}/put' )
    ->json_is( '/paths/~1users~1{user_id}/put/x-mojo-to', { %to, action => 'set' } )
    ;

};

done_testing;
