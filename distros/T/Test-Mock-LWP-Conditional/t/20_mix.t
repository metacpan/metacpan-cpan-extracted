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

my $ua = lwp;
my $another_ua = lwp;

is status(lwp, $httpd->endpoint) => 204, 'no changed';

subtest 'global call affects all instances' => sub {
    Test::Mock::LWP::Conditional->stub_request($httpd->endpoint, res(404));

    is status(lwp, $httpd->endpoint) => 404;
    is status($ua, $httpd->endpoint) => 404;
    is status($another_ua, $httpd->endpoint) => 404;
};

subtest 'instance call affects only self' => sub {
    $ua->stub_request($httpd->endpoint, res(500));

    is status(lwp, $httpd->endpoint) => 404, 'unchanged';
    is status($ua, $httpd->endpoint) => 500, 'changed';
    is status($another_ua, $httpd->endpoint) => 404, 'unchanged';
};

done_testing;

