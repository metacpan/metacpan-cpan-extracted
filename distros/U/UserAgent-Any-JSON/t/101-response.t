use 5.036;
use utf8;

use Test2::V0 -target => 'UserAgent::Any::JSON';
use UserAgent::Any::Fake;

my $raw_content = '{"Foo":"Bar"}';

sub request_handler ($req, $res) {
  $res->headers('Content-Type' => 'application/json');
  $res->content($raw_content);
}

my $ua = CLASS()->new(UserAgent::Any::Fake->new(\&request_handler));
isa_ok($ua, ['UserAgent::Any', 'UserAgent::Any::JSON']);
my $r = $ua->get('ignored');
isa_ok($r, 'UserAgent::Any::JSON::Response');

is($r->status_code, 200, 'status_code');
is($r->success, T(), 'success');
is($r->raw_content, $raw_content, 'raw_content');
is($r->content, $raw_content, 'content');
is($r->json, {Foo => 'Bar'}, 'data');

done_testing;
