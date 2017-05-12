use strict;
use Test::More tests => 3;

use_ok 'Test::WWW::Mechanize::HSS';
use HTTP::Server::Simple::CGI;

my $s = MyApp::Server->new();

my $mech = Test::WWW::Mechanize::HSS->new(
    server => $s,
);

$mech->get_ok('http://localhost/');
$mech->title_like(qr/Hello!/);

package # to prevent indexing by CPAN
  MyApp::Server;
use strict;
use parent 'HTTP::Server::Simple::CGI';