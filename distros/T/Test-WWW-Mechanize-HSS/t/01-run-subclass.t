use strict;
use Test::More tests => 4;

use_ok 'Test::WWW::Mechanize::HSS';
use HTTP::Server::Simple::CGI;
use Data::Dumper;

my $s = MyApp::Server->new();

my $mech = Test::WWW::Mechanize::HSS->new(
    server => $s,
);

$mech->get_ok('http://localhost/');
$mech->title_like(qr/Hallo/);

my %found_cookie;
$mech->cookie_jar->scan(sub {$found_cookie{ $_[1] } = $_[2]} );
is $found_cookie{'foo'}, 'bar'
    or diag "Found cookies: " . Dumper \%found_cookie;

package # to prevent indexing by CPAN
  MyApp::Server;
use strict;
use parent 'HTTP::Server::Simple::CGI';

sub handle_request {
    print join "\r\n", 
        "HTTP/1.1 200 OK",
        "Set-Cookie: foo=bar",
        "Content-Type: text/html",
        "\r\n",
        <<PAGE;
<html><head><title>Hallo</title><body><h1>Hallo</h1></body></html>
PAGE
};