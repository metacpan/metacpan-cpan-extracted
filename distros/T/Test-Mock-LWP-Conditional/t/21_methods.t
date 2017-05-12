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

is status(lwp, $httpd->endpoint) => 204, 'no changed';

subtest 'global call affects all methods' => sub {
    Test::Mock::LWP::Conditional->stub_request($httpd->endpoint, res(404));

    is lwp->get($httpd->endpoint)->code  => 404, 'GET ok';
    is lwp->post($httpd->endpoint)->code => 404, 'POST ok';
    is lwp->head($httpd->endpoint)->code => 404, 'HEAD ok';

    is lwp->request(req(PUT    => $httpd->endpoint))->code => 404, 'PUT ok';
    is lwp->request(req(DELETE => $httpd->endpoint))->code => 404, 'DELETE ok';
};

done_testing;

