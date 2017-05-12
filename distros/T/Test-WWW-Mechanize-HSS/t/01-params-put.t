use strict;
use Test::More tests => 6;

use_ok 'Test::WWW::Mechanize::HSS';
use HTTP::Server::Simple::CGI;
use Data::Dumper;

my $s = MyApp::Server->new();

my $mech = Test::WWW::Mechanize::HSS->new(
    server => $s,
);

$mech->get_ok('http://localhost/', 'We can get the starting URL');
$mech->submit_form_ok({ with_fields => { foo => 'bar', boo => 'baz' }}, 'We can submit form fields');
$mech->title_like(qr/Hallo/, 'We get some HTML back');
$mech->content_like(qr/foo is bar/, 'Parameter foo was received on the backend');
$mech->content_like(qr/boo is baz/, 'Parameter boo was received on the backend');

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
        "Content-Type: text/html",
        "",
        qq(<html><head><title>Hallo</title></head><body><h1>Hallo</h1>
           Params are [$content]
           <form name="test" method="POST" action="/">
           <input type="text" name="foo">
           <input type="text" name="boo">
           <input type="submit>
           </form>
           </body></html>)
        ;
};