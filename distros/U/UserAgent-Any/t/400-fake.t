use 5.036;

use AnyEvent;
use Encode 'encode';
use Test2::V0 -target => 'UserAgent::Any::Fake';

{
  sub fake_handler ($req, $res) {
    $res->headers(Foo => 'bar', Foo => 'baz', Bin => 'bang');
    $res->header(blah => [qw(abc def)]);
    $res->status_code(300);
    $res->content('the content');
  }

  my $fake = CLASS()->new(\&fake_handler);
  isa_ok($fake, 'UserAgent::Any');

  my $r = $fake->get('example.com', Foo => 'bar');
  isa_ok($r, 'UserAgent::Any::Response');

  is($r->status_code, 300, 'status code');
  is($r->success, F(), 'is not success');
  is($r->raw_content, 'the content', 'raw content');
  is([$r->header('Foo')], [qw(bar baz)], 'header array');
  is(scalar($r->header('blah')), 'abc,def', 'header scalar');
  is([$r->headers], [Bin => 'bang', Foo => 'bar', Foo => 'baz', blah => 'abc', blah => 'def'], 'headers order');
}


{
  sub test_headers_order ($req, $res) {
    is([$req->headers], [Bin => 'bang', Foo => 'bar', Foo => 'baz'], 'request headers order');
  }
  my $fake = CLASS()->new(\&test_headers_order);
  my $r = $fake->get('example.com', Bin => 'bang', Foo => 'bar', Foo => 'baz');
  is($r->status_code, 200, 'request header status code');
  is($r->success, T(), 'is success');
}


done_testing;
