use strict;
use Test::More 0.98;
use Test::Exception;
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

ok my $res2 = $mailgun->message([
    from => 'test@perl.example.com',
    to => 'kan.fushihara@gmail.com',
    subject => 'test message',
    text => 'Hello, perl',
    attachment => [ 't/01_message.t' ],
    'o:testmode' => 'true',
]);

is $res2->{message}, 'Queued. Thank you.';
note $res2;

dies_ok { my $res3 = $mailgun->message('scalar'); }, 'unsupport', 'message support only hashref or arrayref';

done_testing;

