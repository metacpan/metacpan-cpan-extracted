use 5.036;
use utf8;

use Encode 'encode';
use JSON::PP;
use Test2::V0 -target => 'UserAgent::Any::JSON';

use UserAgent::Any::Fake;

sub request_handler ($req, $res) {
  if ($req->url eq '/pretty') {
    like($req->content, qr/^\[\n\s+{\n\s+"foo"\s+:\s+"bar"\n\s+},\n\s+.*/, 'pretty content');
  } elsif ($req->url eq '/not_pretty') {
    is($req->content, '[{"foo":"bar"},{"bin":"baz","foo":"bar"}]', 'not pretty content');
  }
}

my $ua_not_pretty = UserAgent::Any::JSON->new(
  ua => UserAgent::Any::Fake->new(\&request_handler),
  json => JSON::PP->new->pretty(0)->canonical(1));

my $ua_pretty = UserAgent::Any::JSON->new(
  ua => UserAgent::Any::Fake->new(\&request_handler),
  json => JSON::PP->new->pretty(1)->canonical(1));

is($ua_not_pretty->post('/not_pretty', [{foo => "bar"}, {foo => "bar", bin => "baz"}])->status_code, 200);
is($ua_pretty->post('/pretty', [{foo => "bar"}, {foo => "bar", bin => "baz"}])->status_code, 200);

is(exists $INC{'JSON.pm'}, F(), 'JSON not loaded');

done_testing;
