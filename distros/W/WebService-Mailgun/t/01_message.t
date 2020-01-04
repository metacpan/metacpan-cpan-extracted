use strict;
use Test::More 0.98;
use WebService::Mailgun;

my $mailgun = WebService::Mailgun->new(
    api_key => 'key-389807c554fdfe0a7757adf0650f7768',
    domain  => 'sandbox56435abd76e84fa6b03de82540e11271.mailgun.org',
);

ok my $res = $mailgun->message({
    from => 'test@perl.example.com',
    to => 'kan.fushihara@gmail.com',
    subject => 'test message',
    text => 'Hello, perl',
    'o:testmode' => 'true',
});

is $res->{message}, 'Queued. Thank you.';
note $res->{id};

done_testing;

