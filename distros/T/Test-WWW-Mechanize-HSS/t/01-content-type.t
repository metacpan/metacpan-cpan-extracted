use strict;
use Test::More tests => 3;

use_ok 'Test::WWW::Mechanize::HSS';

my $s = MyApp::Server->new();

my $mech = Test::WWW::Mechanize::HSS->new(
    server => $s,
);

$mech->get_ok('http://localhost/', 'We can get the starting URL');
is $mech->ct, 'application/custom', 'Custom content type is passed through';

package # to prevent indexing by CPAN
  MyApp::Server;
use strict;
use parent 'HTTP::Server::Simple::CGI';

sub handle_request {
    my ($self,$cgi) = @_;
    $self->page($cgi);
};

sub page {
    my ($self,$cgi) = @_;
    my $content = join "<br/>",
        map { "$_ is " . $cgi->param($_) } $cgi->param;
    print join "\r\n", 
        "HTTP/1.1 200 OK",
        "Content-Type: application/custom",
        "",
        <<PAGE;
<html><head><title>Hallo</title><body><h1>Hallo</h1>$content</body></html>
PAGE
};