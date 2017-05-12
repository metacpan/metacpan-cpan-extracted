use strictures 1;
use Test::More 0.88;

{
  package TestApp;

  use Web::Simple;

  sub dispatch_request {
    sub (/foo/...) {
      sub (GET) { [ 200, [], [ $_[PSGI_ENV]->{PATH_INFO} ] ] }
    },
    sub (POST) { [ 200, [], [ $_[PSGI_ENV]->{PATH_INFO} ] ] }
  }
}

my $app = TestApp->new->to_psgi_app;

my $call = sub { $app->({
  SCRIPT_NAME => '/base', PATH_INFO => '/foo/bar', REQUEST_METHOD => shift
})->[2]->[0] };

is($call->('GET'), '/bar', 'recursive strip ok');
is($call->('POST'), '/foo/bar', 'later dispatchers unaffected');

done_testing;
