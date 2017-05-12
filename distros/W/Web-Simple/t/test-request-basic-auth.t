use strictures 1;
use Test::More 0.88;

my $auth_result;
my @auth_args;

{
  package TestApp;

  use Web::Simple;
  use Plack::Middleware::Auth::Basic;

  sub dispatch_request {
    sub () {
      Plack::Middleware::Auth::Basic->new(
        authenticator => sub { 
          @auth_args = @_; return $auth_result
        }
      )
    },
    sub () {
      [ 200, [ 'Content-type' => 'text/plain' ], [ 'Woo' ] ]
    }
  }
}

my $ta = TestApp->new;

my $res = $ta->run_test_request(GET => '/');

is($res->code, '401', 'Auth failed with no user/pass');
ok(!@auth_args, 'Auth callback never called with no user/pass');

$res = $ta->run_test_request(GET => 'bob:secret@/');

is($res->code, '401', 'Auth failed with bad user/pass');
is($auth_args[0], 'bob', 'Username passed ok');
is($auth_args[1], 'secret', 'Password passed ok');

$auth_result = 1;
@auth_args = ();

$res = $ta->run_test_request(GET => '/');

is($res->code, '401', 'Auth failed with no user/pass');
ok(!@auth_args, 'Auth callback never called with no user/pass');

$res = $ta->run_test_request(GET => 'bob:secret@/');

is($res->code, '200', 'Auth succeeded with good user/pass');
is($auth_args[0], 'bob', 'Username passed ok');
is($auth_args[1], 'secret', 'Password passed ok');

done_testing;
