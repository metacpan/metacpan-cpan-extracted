use strict;
use warnings;
use Test::More;
use Test::Fake::HTTPD;
use Test::Mock::LWP::Conditional;
use LWP::UserAgent;
use HTTP::Response;
use HTTP::Request;

sub lwp { LWP::UserAgent->new }
sub res { HTTP::Response->new(@_) }
sub status { $_[0]->get($_[1])->code }

sub req { HTTP::Request->new(@_) }

my $httpd = run_http_server { res(204) };
my $ua = lwp;

subtest 'reset all stubs' => sub {
    Test::Mock::LWP::Conditional->stub_request($httpd->endpoint, res(404));
    $ua->stub_request($httpd->endpoint, res(403));
    is status(lwp, $httpd->endpoint) => 404, 'changed';
    is status($ua, $httpd->endpoint) => 403, 'changed';

    Test::Mock::LWP::Conditional->reset_all;
    is status(lwp, $httpd->endpoint) => 204, 'reset';
    is status($ua, $httpd->endpoint) => 204, 'reset';
};

done_testing;

