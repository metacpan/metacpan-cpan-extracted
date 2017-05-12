use strict;
use warnings;
use Test::More;
use Test::Fake::HTTPD;
use Test::Mock::LWP::Conditional;
use LWP::UserAgent;
use HTTP::Response;

sub lwp { LWP::UserAgent->new }
sub res { HTTP::Response->new(@_) }
sub status { $_[0]->get($_[1])->code }

my $httpd = run_http_server { res(204) };

is status(lwp, $httpd->endpoint) => 204, 'no changed';

subtest 'define stubs at same url' => sub {
    Test::Mock::LWP::Conditional->stub_request($httpd->endpoint, res(400));
    Test::Mock::LWP::Conditional->stub_request($httpd->endpoint, res(403));
    Test::Mock::LWP::Conditional->stub_request($httpd->endpoint, res(404));

    is status(lwp, $httpd->endpoint) => 400, '1st returns 400';
    is status(lwp, $httpd->endpoint) => 403, '2nd returns 403';
    is status(lwp, $httpd->endpoint) => 404, '3rd returns 404';
    is status(lwp, $httpd->endpoint) => 404, '4th returns 404, too';
};

subtest 'define instance stubs at same url' => sub {
    my $ua = lwp;
    $ua->stub_request($httpd->endpoint, res(500));
    $ua->stub_request($httpd->endpoint, res(503));

    is status($ua, $httpd->endpoint) => 500, '1st returns 500';
    is status($ua, $httpd->endpoint) => 503, '2nd returns 503';
    is status($ua, $httpd->endpoint) => 503, '3rd returns 503, too';
};

done_testing;

