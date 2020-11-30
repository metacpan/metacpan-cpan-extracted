use strict;
use warnings;
use utf8;

use Test::More;
use lib 'lib';
use FindBin qw($Bin $RealBin);
use lib "$Bin/../../Gtk3-WebKit2/lib";
use File::Slurper 'read_text';
use Test::Fake::HTTPD;
use URI;

#Running tests as root will sometimes spawn an X11 that cannot be closed automatically and leave the test hanging
plan skip_all => 'Tests run as root may hang due to X11 server not closing.' unless $>;

use_ok 'WWW::WebKit2';

my $timeout = 1000;

my $webkit= WWW::WebKit2->new(xvfb => 1);
eval { $webkit->init; };
if ($@ and $@ =~ /\ACould not start Xvfb/) {
    $webkit = WWW::WebKit2->new();
    $webkit->init;
}
elsif ($@) {
    diag($@);
    fail('init webkit');
}
ok(1, 'init done');


my $httpd = Test::Fake::HTTPD->new;

$httpd->run(sub {
    my $req = shift;
    return [ 200, [ 'Content-Type', 'text/html' ], [ read_text("$Bin/test/cookie.html") ] ];
});

$webkit->open($httpd->endpoint);

#check get_cookie_domains
my @cookie_domains = $webkit->get_cookie_domains();
like($httpd->endpoint, qr/$cookie_domains[0]/, 'found in cookie domain list');

#check actual cookies
my $cookies = $webkit->get_cookies_for_uri($httpd->endpoint);
is($cookies->[0]->{name}, 'foo', 'cookie name found in Cookie Manager');
is($cookies->[0]->{value}, 'bar', 'cookie name found in Cookie Manager');


done_testing;
