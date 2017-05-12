use strict;
use Test::More tests => 5;

use_ok 'Test::WWW::Mechanize::HSS';
use HTTP::Server::Simple::CGI;
use Data::Dumper;

my $s = MyApp::Server->new();

my $mech = Test::WWW::Mechanize::HSS->new(
    server => $s,
);

$mech->get_ok('http://localhost/', 'We can get the starting URL');
$mech->title_like(qr/Hallo/, 'We get some HTML back');
is $mech->uri, 'http://localhost/foo', 'And we were redirected in the meantime';

my %found_cookie;
$mech->cookie_jar->scan(sub {$found_cookie{ $_[1] } = $_[2]} );
is $found_cookie{'foo'}, 'bar', 'Setting Cookies via redirect works'
    or diag "Found cookies: " . Dumper \%found_cookie;

package # to prevent indexing by CPAN
  MyApp::Server;
use strict;
use parent 'HTTP::Server::Simple::CGI';

sub handle_request {
    my ($self,$cgi) = @_;
    if ($cgi->path_info eq '/foo') {
        $self->page
    } else {
        $self->redirect('/foo')
    };
};

sub redirect {
    my ($self,$loc) = @_;
    print join "\r\n", 
        "HTTP/1.1 302 Elsewhere",
        "Location: $loc",
        "Set-Cookie: foo=baz",
        ""
    ;
};

sub page {
    print join "\r\n", 
        "HTTP/1.1 200 OK",
        "Set-Cookie: foo=bar",
        "Content-Type: text/html",
        "",
        '<html><head><title>Hallo</title><body><h1>Hallo</h1></body></html>'
        ;
};