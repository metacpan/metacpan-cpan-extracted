use strict;
use warnings;
use Test::More;

use Unblock::HTTP1::Server;

my @error;
my $server = Unblock::HTTP1::Server->new(
    on_request => sub { fail('ambiguous request must not reach application') },
    on_error => sub { push @error, $_[1] },
);
$server->input(
    "POST / HTTP/1.1\r\nHost: example.test\r\n" .
    "Content-Length: 4\r\nTransfer-Encoding: chunked\r\n\r\n"
);
like($server->output, qr/^HTTP\/1\.1 400 /, 'ambiguous request receives 400');
ok($server->is_closed, 'protocol error closes server engine');
like($error[0], qr/Transfer-Encoding.*Content-Length/, 'framing error is explicit');

done_testing;
