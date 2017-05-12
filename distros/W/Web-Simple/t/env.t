use strict;
use warnings FATAL => 'all';

use Test::More 'no_plan';
use Plack::Test;

{
  use Web::Simple 'EnvTest';
  package EnvTest;
  sub dispatch_request  {
    sub (GET) {
      my $env = $_[PSGI_ENV];
      [ 200,
        [ "Content-type" => "text/plain" ],
        [ 'foo' ]
      ]
    },
  }
}

my $app = EnvTest->new;

ok $app->run_test_request(GET => 'http://localhost/')->is_success;
