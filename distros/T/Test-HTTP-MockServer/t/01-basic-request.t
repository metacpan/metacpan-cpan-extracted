use Test::More;
use LWP::UserAgent;
use IO::Handle;

use_ok('Test::HTTP::MockServer');

my $server = Test::HTTP::MockServer->new();
my $url = $server->url_base();
my $ua = LWP::UserAgent->new;

STDOUT->autoflush(1);
STDERR->autoflush(1);

my $closed_over_counter;
my $handle_request_phase1 = sub {
    my ($request, $response) = @_;
    $response->content("Phase1: ".$closed_over_counter++)
};

$server->start_mock_server($handle_request_phase1);

my $res = $ua->get($url);
is($res->code, 200, 'default response code');
is($res->message, 'OK', 'default response message');
is($res->content, 'Phase1: 0', 'got the correct response');
$res = $ua->get($url);
is($res->content, 'Phase1: 1', 'got the correct response');

$server->stop_mock_server();

my $handle_request_phase2 = sub {
    my ($request, $response) = @_;
    die "phase2\n";
};
$server->start_mock_server($handle_request_phase2);

$res = $ua->get($url);
is($res->code, 500, 'error response code');
is($res->message, 'Internal Server Error', 'error response message');
is($res->content, "phase2\n", 'got the correct response');

$res = $ua->get($url);
is($res->code, 500, 'error response code');
is($res->message, 'Internal Server Error', 'error response message');
is($res->content, "phase2\n", 'got the correct response');

$server->stop_mock_server();

my $handle_request_phase3 = sub {
    my ($request, $response) = @_;
    $response->code('204');
    $response->message('Accepted');
    $response->header('Content-type' => 'application/json');
    $response->content('[]');
};
$server->start_mock_server($handle_request_phase3);

$res = $ua->get($url);
is($res->code, 204, 'custom response code');
is($res->message, 'Accepted', 'custom response message');
is($res->header('Content-type'), 'application/json', 'custom header');
is($res->content, "[]", 'returned content');

$server->stop_mock_server();


done_testing();

__END__

Copyright 2016 Bloomberg Finance L.P.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

