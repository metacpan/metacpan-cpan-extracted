use strict;
use Test::More 0.98;
use WebService::Mailgun;

$WebService::Mailgun::API_BASE = 'api.example.com/v0.1';

my $mailgun = WebService::Mailgun->new(
    api_key => 'key-389807c554fdfe0a7757adf0650f7768',
    domain  => 'sandbox56435abd76e84fa6b03de82540e11271.mailgun.org',
);

my $res = $mailgun->message({
    from => 'test@perl.example.com',
    to => 'kan.fushihara@gmail.com',
    subject => 'test message',
    text => 'Hello, perl',
    'o:testmode' => 'true',
});

ok !$res, "can't access API server";

like $mailgun->error, qr/Cannot resolve host name: /, 'error message';
like $mailgun->error_status, qr/500 Internal Response:/, 'status line';

done_testing;

