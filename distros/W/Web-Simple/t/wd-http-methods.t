use strictures 1;
use Test::More 0.88;

{
  package t::Web::Simple::HTTPMethods;

  use Web::Simple;
  use Web::Dispatch::HTTPMethods;

  sub as_text {
    [200, ['Content-Type' => 'text/plain'],
      [$_[0]->{REQUEST_METHOD}, $_[0]->{REQUEST_URI}] ]
  }

  sub dispatch_request {
    sub (/get) {
      GET { as_text(pop) }
    },
    sub (/get-head-options) {
      GET { as_text(pop) }
      HEAD { [204,[],[]] }
      OPTIONS { [204,[],[]] },
    },
    sub (/get-post-put) {
      GET { as_text(pop) }
      POST { as_text(pop) }
      PUT { as_text(pop) }
    },
  }
}

ok my $app = t::Web::Simple::HTTPMethods->new,
  'made app';

for my $uri ('http://localhost/get-post-put') {

  ## Check allowed methods and responses
  for(ok my $res = $app->run_test_request(GET => $uri)) {
    is $res->content, 'GET/get-post-put';
  }

  for(ok my $res = $app->run_test_request(POST => $uri)) {
    is $res->content, 'POST/get-post-put';
  }

  for(ok my $res = $app->run_test_request(PUT => $uri)) {
    is $res->content, 'PUT/get-post-put';
  }

  ## Since GET is allowed, check for implict HEAD
  for(ok my $head = $app->run_test_request(HEAD => $uri)) {
    is $head->code, 200;
    is $head->content, '';
  }

  ## Check the implicit support for OPTIONS
  for(ok my $options = $app->run_test_request(OPTIONS => $uri)) {
    is $options->code, 200;
    is $options->content, '';
    is $options->header('Allow'), 'GET,HEAD,POST,PUT,OPTIONS';
  }

  ## Check implicitly added not allowed
  for(ok my $not_allowed = $app->run_test_request(DELETE => $uri)) {
    is $not_allowed->code, 405;
    is $not_allowed->content, 'Method Not Allowed';
    is $not_allowed->header('Allow'), 'GET,HEAD,POST,PUT,OPTIONS';
  }

}

for my $uri ('http://localhost/get-head-options') {

  ## Check allowed methods and responses
  for(ok my $res = $app->run_test_request(GET => $uri)) {
    is $res->content, 'GET/get-head-options';
  }

  for(ok my $head = $app->run_test_request(HEAD => $uri)) {
    is $head->code, 204;
    is $head->content, '';
  }

  for(ok my $options = $app->run_test_request(OPTIONS => $uri)) {
    is $options->code, 204;
    is $options->content, '';
  }

  ## Check implicitly added not allowed
  for(ok my $not_allowed = $app->run_test_request(PUT => $uri)) {
    is $not_allowed->code, 405;
    is $not_allowed->content, 'Method Not Allowed';
    is $not_allowed->header('Allow'), 'GET,HEAD,OPTIONS';
  }

}

for my $uri ('http://localhost/get') {

  ## Check allowed methods and responses
  for(ok my $res = $app->run_test_request(GET => $uri)) {
    is $res->content, 'GET/get';
  }

  ## Check implicitly added not allowed
  for(ok my $not_allowed = $app->run_test_request(PUT => $uri)) {
    is $not_allowed->code, 405;
    is $not_allowed->content, 'Method Not Allowed';
    is $not_allowed->header('Allow'), 'GET,HEAD,OPTIONS';
  }

  ## Since GET is allowed, check for implict HEAD
  for(ok my $head = $app->run_test_request(HEAD => $uri)) {
    is $head->code, 200;
    is $head->content, '';
  }

}

done_testing;
