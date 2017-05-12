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

is status(lwp, $httpd->endpoint) => 204, 'returns a real response';

Test::Mock::LWP::Conditional->stub_request(
    $httpd->endpoint => res(404)
);
is status(lwp, $httpd->endpoint) => 404, 'returns a stub response';

Test::Mock::LWP::Conditional->stub_request(
    $httpd->endpoint => sub { res(500) }
);
is status(lwp, $httpd->endpoint) => 500, 'returns a code stubbed response';

my $url = $httpd->endpoint;
my $regex = qr!$url/foo/ba[rz]/!;
Test::Mock::LWP::Conditional->stub_request(
    $regex => sub { res(500) }
);
is status(lwp, "$url/foo/bar/") => 500, 'returns a code stubbed response';
is status(lwp, "$url/foo/baz/") => 500, 'returns a code stubbed response';


done_testing;

