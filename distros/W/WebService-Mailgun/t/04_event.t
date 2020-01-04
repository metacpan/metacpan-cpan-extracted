use strict;
use Test::More 0.98;
use Test::Exception;
use WebService::Mailgun;
use JSON::XS;
use Time::Piece;
use Time::Seconds;

my $mailgun = WebService::Mailgun->new(
    api_key => 'key-389807c554fdfe0a7757adf0650f7768',
    domain  => 'sandbox56435abd76e84fa6b03de82540e11271.mailgun.org',
    RaiseError => 1,
);

subtest 'get events' => sub {
    my $from = Time::Piece->strptime('2019-01-01 00:00:00', '%Y-%m-%d %H:%M:%S');
    my $to = Time::Piece->strptime('2020-01-01 00:00:00', '%Y-%m-%d %H:%M:%S');
    my ($res, undef) = $mailgun->event({
            begin => $from->epoch(),
            end => $to->epoch(),
    });
    ok $res;
    is scalar(@$res), 110, 'event results is 110 (2019-2020)';
    note explain $res;
};

done_testing;
