#!perl
use Test::More tests => 5;
use WWW::Twilio::API;

my $resp;
my $t = WWW::Twilio::API->new;

{
    $resp = $t->_build_content(
        From => '+12345678901',
        To   => '+19876543210',
        Mack => undef,
        Url  => 'http://www.google.com?message=this+should+work'
    );

    like($resp, qr(Url=http%3A%2F%2Fwww.google.com%3Fmessage%3Dthis%2Bshould%2Bwork\b), "url encoded");
    like($resp, qr(To=%2B19876543210\b),                                                "phone encoded");
    like($resp, qr(Mack=&\b),                                                           "empty string preserved");
}

{
    $resp = $t->_build_content(From => '+12345678901', StatusCallbackEvent => 'foo', StatusCallbackEvent => 'bar',);

    like($resp, qr(StatusCallbackEvent=foo), "one param");
    like($resp, qr(StatusCallbackEvent=bar), "two params");
}
