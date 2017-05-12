use strictures 1;
use Test::More 0.88;

{
  package t::Web::Simple::MatchHome;

  use Web::Simple;

  sub as_text {
    [200, ['Content-Type' => 'text/plain'],
      [$_[0]->{REQUEST_METHOD}, $_[0]->{REQUEST_URI}] ]
  }

  sub dispatch_request {
    sub (/foo...) {
      sub (~) { as_text(pop) },
      sub (/bar)  { as_text(pop) },
      sub (/baz)  { as_text(pop) },
      sub (/*) { as_text(pop) },
      sub (/bork...) {
        sub (~) { as_text(pop) },
        sub (/bar)  { as_text(pop) },
      }
    },
    sub (/...)  {
      sub (/baz) { as_text(pop) },
      sub (/fob...) {
        sub (~) { as_text(pop) },
        sub (/bar)  { as_text(pop) },
      }
    }
  }
}

ok my $app = t::Web::Simple::MatchHome->new,
  'made app';

for(ok my $res = $app->run_test_request(GET => '/foo')) {
  is $res->content, 'GET/foo';
}

for(ok my $res = $app->run_test_request(GET => '/foo/bar')) {
  is $res->content, 'GET/foo/bar';
}

for(ok my $res = $app->run_test_request(GET => '/foo/baz')) {
  is $res->content, 'GET/foo/baz';
}

for(ok my $res = $app->run_test_request(GET => '/foo/id')) {
  is $res->content, 'GET/foo/id';
}


for(ok my $res = $app->run_test_request(GET => '/foo/bork')) {
  is $res->content, 'GET/foo/bork';
}

for(ok my $res = $app->run_test_request(GET => '/foo/bork/bar')) {
  is $res->content, 'GET/foo/bork/bar';
}

for(ok my $res = $app->run_test_request(GET => '/fob')) {
  is $res->content, 'GET/fob';
}

for(ok my $res = $app->run_test_request(GET => '/baz')) {
  is $res->content, 'GET/baz';
}

for(ok my $res = $app->run_test_request(GET => '/fob/bar')) {
  is $res->content, 'GET/fob/bar';
}

done_testing;
