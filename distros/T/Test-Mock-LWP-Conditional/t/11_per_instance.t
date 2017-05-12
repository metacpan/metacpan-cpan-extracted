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
is status($ua, $httpd->endpoint) => 204, 'returns a real response';

$ua->stub_request($httpd->endpoint => res(404));
is status($ua, $httpd->endpoint) => 404, 'returns a stub response';

my $new_ua = lwp;
is status($new_ua, $httpd->endpoint) => 204, 'another instance returns a real response';

my $another_ua = lwp;
my $url = $httpd->endpoint;
my $regex = qr!$url/foo/ba[rz]/!;
is status($another_ua, $url) => 204, 'returns a real response';

$another_ua->stub_request($regex => res(404));
is status($another_ua, "$url/foo/bar/") => 404, 'returns a stub response';
is status($another_ua, "$url/foo/baz/") => 404, 'returns a stub response';
is status($another_ua, "$url/foo/bee/") => 204, 'returns a real response';

done_testing;

