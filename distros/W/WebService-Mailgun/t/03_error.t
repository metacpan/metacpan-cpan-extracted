use strict;
use Test::More 0.98;
use WebService::Mailgun;

# this test never reaches a real API server, so credentials can be dummy.
$WebService::Mailgun::API_BASE = 'api.example.com./v0.1';

my $mailgun = WebService::Mailgun->new(
    api_key => 'dummy-api-key',
    domain  => 'example.com',
);

my $res = $mailgun->message({
    from => 'test@perl.example.com',
    to => 'user@example.com',
    subject => 'test message',
    text => 'Hello, perl',
    'o:testmode' => 'true',
});

ok !$res, "can't access API server";

like $mailgun->error, qr/Cannot resolve host name: /, 'error message';
like $mailgun->error_status, qr/500 Internal Response:/, 'status line';

done_testing;
