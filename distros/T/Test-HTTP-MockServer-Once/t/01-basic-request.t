use Test::More;
use LWP::UserAgent;
use IO::Handle;
use Async;
use Storable qw(thaw);

use_ok('Test::HTTP::MockServer::Once');

my $server = Test::HTTP::MockServer::Once->new(port => 3000);
my $ua = LWP::UserAgent->new(timeout => 1);

STDOUT->autoflush(1);
STDERR->autoflush(1);

is($server->port, 3000, "Configuring a specific port works");

$server = Test::HTTP::MockServer::Once->new();
my $url = $server->base_url();
ok(defined($server->port), "Not configuring a port works");

my $request;
my $handle_request = sub {
	my ($request, $response) = @_;
    $response->content("Hello!");
};

# 200
note("Starting web server on ".$server->base_url());
my $proc = AsyncTimeout->new(sub { $server->start_mock_server($handle_request) }, 30, "TIMEOUT");
#~ my $result = $proc->result('force completion');
#~ BAIL_OUT "No request received" if($proc->result eq "TIMEOUT");
#~ my $interaction = thaw $proc->result;
#~ note("URI: ".$interaction->{request}->uri->as_string);

my $res = $ua->get($url);
is($res->code, 200, 'default response code');
is($res->message, 'OK', 'default response message');
is($res->content, 'Hello!', 'got the correct response');

# 500
my $handle_request_failure = sub {
	my ($request, $response) = @_;
	die "Bollocks\n";
};
note("Starting web server on ".$server->base_url());
$proc = AsyncTimeout->new(sub { $server->start_mock_server($handle_request_failure) }, 30, "TIMEOUT");

$res = $ua->get($url);
is($res->code, 500, 'error response code');
is($res->message, 'Internal Server Error', 'error response message');
is($res->content, "Bollocks\n", 'got the correct response');

# Custom
my $handle_request_custom = sub {
	my ($request, $response) = @_;
	$response->code('204');
	$response->message('Accepted');
	$response->header('Content-type' => 'application/json');
	$response->content('[]');
};
$proc = AsyncTimeout->new(sub { $server->start_mock_server($handle_request_custom) }, 30, "TIMEOUT");

$res = $ua->get($url);
is($res->code, 204, 'custom response code');
is($res->message, 'Accepted', 'custom response message');
is($res->header('Content-type'), 'application/json', 'custom header');
is($res->content, "[]", 'returned content');

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

