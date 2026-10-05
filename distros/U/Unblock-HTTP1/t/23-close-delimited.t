use strict;
use warnings;
use Test::More;

use Uniform::HTTP::Request;
use Unblock::HTTP1::Client;

my $body = '';
my $complete = 0;
my $client = Unblock::HTTP1::Client->new;
$client->request(
    Uniform::HTTP::Request->new(
        method => 'GET', target => '/', authority => 'example.test',
    ),
    on_body => sub { $body .= $_[2] },
    on_complete => sub { $complete++ },
    on_error => sub { die "client error: $_[1]" },
);
$client->output;
$client->input(
    "HTTP/1.0 200 OK\r\nContent-Type: text/plain\r\n\r\nclose-body"
);
is($body, 'close-body', 'close-delimited body delivered before EOF');
is($complete, 0, 'close-delimited response waits for EOF');
$client->input_eof;
is($complete, 1, 'EOF completes close-delimited response');
ok($client->is_closed, 'close-delimited connection is not reusable');

done_testing;
