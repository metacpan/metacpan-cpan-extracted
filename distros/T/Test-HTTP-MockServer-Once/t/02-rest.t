use Test::More;
use LWP::UserAgent;
use IO::Handle;
use Async;

use_ok('Test::HTTP::MockServer::Once');
use_ok('Test::HTTP::MockServer::Once::REST');

my $server = Test::HTTP::MockServer::Once->new();
my $url = $server->base_url();
my $ua = LWP::UserAgent->new;

my $rest = Test::HTTP::MockServer::Once::REST->new(
	'methoda_GET'  => qr{^GET /foo/([a-z0-9]+)/bar$},
	'methoda_POST' => qr{^POST /foo/([a-z0-9]+)/bar$},
);

{ package MockApp1;
  sub new {
	  return bless {}, __PACKAGE__;
  }
  sub methoda_GET {
	  my ($self, $req, $res, $cap, $data) = @_;
	  return [1,@$cap,3];
  }
  sub methoda_POST {
	  my ($self, $req, $res, $cap, $data) = @_;
	  return [1,@$cap,$data];
  }
}

my $proc = AsyncTimeout->new(sub { $server->start_mock_server($rest->wrap_object(MockApp1->new())) }, 30, "TIMEOUT");

my $res = $ua->get(
	$url.'/foo/2/bar',
	'Accept' => 'application/json'
);
is($res->code, 200, 'default response code');
is($res->message, 'OK', 'default response message');
is($res->content, '[1,"2",3]', 'got the correct response');

$proc = AsyncTimeout->new(sub { $server->start_mock_server($rest->wrap_object(MockApp1->new())) }, 30, "TIMEOUT");
$res = $ua->post(
	$url.'/foo/2/bar',
	'Content-type' => 'application/json',
	'Accept'       => 'application/json',
	Content        => '{ "a": "b" }',
);
is($res->code, 200, 'default response code');
is($res->message, 'OK', 'default response message');
is($res->content, '[1,"2",{"a":"b"}]', 'got the correct response');

my $mockapp = MockApp1->new();
$proc = AsyncTimeout->new(sub { $server->start_mock_server($rest->wrap_hash({
	methoda_GET => sub { $mockapp->methoda_GET(@_) },
	methoda_POST => sub { $mockapp->methoda_POST(@_) },
})) }, 30, "TIMEOUT");

$res = $ua->get(
	$url.'/foo/2/bar',
	'Accept' => 'application/json'
);
is($res->code, 200, 'default response code');
is($res->message, 'OK', 'default response message');
is($res->content, '[1,"2",3]', 'got the correct response');

$proc = AsyncTimeout->new(sub { $server->start_mock_server($rest->wrap_hash({
	methoda_GET => sub { $mockapp->methoda_GET(@_) },
	methoda_POST => sub { $mockapp->methoda_POST(@_) },
})) }, 30, "TIMEOUT");
$res = $ua->post(
	$url.'/foo/2/bar',
	'Content-type' => 'application/json',
	'Accept'       => 'application/json',
	Content        => '{ "a": "b" }',
);
is($res->code, 200, 'default response code');
is($res->message, 'OK', 'default response message');
is($res->content, '[1,"2",{"a":"b"}]', 'got the correct response');

done_testing();

__END__

Copyright 2016 Bloomberg Finance L.P., 2021 on Ian Gibbs

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

