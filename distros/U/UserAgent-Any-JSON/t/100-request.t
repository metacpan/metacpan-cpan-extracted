use 5.036;
use utf8;

use Data::Dumper;
use Test2::V0 -target => 'UserAgent::Any::JSON';
use UserAgent::Any::Fake;

$Data::Dumper::Terse = 1;

sub request_handler ($req, $res) {
  my @out = ($req->url, $req->headers);
  push @out, $req->content if $req->content;
  $res->content(Dumper(\@out));
}

my $ua = CLASS()->new(UserAgent::Any::Fake->new(\&request_handler));

sub test_get (@args) {
  my $data = eval $ua->get(@args)->content;
  die "$@ ($!)" if $@;
  return $data;
}

sub test_post (@args) {
  return eval $ua->post(@args)->content;
}

my @HDRS = (Accept => 'application/json', 'Content-Type' => 'application/json');

is(test_get("http://example.com"), ['http://example.com', @HDRS], 'get no args');
like(dies { test_get("http://example.com", 'Foo') }, qr/Invalid number of arguments/, 'get odd number of args');
is(test_get("http://example.com", Foo => 'Bar'), ['http://example.com', @HDRS, Foo => 'Bar'], 'get no args');

is(test_post("http://example.com"), ['http://example.com', @HDRS], 'post no args body');
is(test_post("http://example.com", 'Foo'), ['http://example.com', @HDRS, '"Foo"'], 'post only body');
is(test_post("http://example.com", Foo => 'Bar'), ['http://example.com', @HDRS, Foo => 'Bar'], 'post no body');
is(test_post("http://example.com", Foo => 'Bar', 'Baz'), ['http://example.com', @HDRS, Foo => 'Bar', '"Baz"'], 'post args and body');

is(test_post("http://example.com", { Foo => 'Bar' }), ['http://example.com', @HDRS, '{"Foo":"Bar"}'], 'post with JSON');

done_testing;
