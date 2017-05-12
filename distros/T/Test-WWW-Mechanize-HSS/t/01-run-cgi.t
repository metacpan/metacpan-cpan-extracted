use strict;
use Test::More tests => 3;

use_ok 'Test::WWW::Mechanize::HSS';
use HTTP::Server::Simple::CGI;

my $s = HTTP::Server::Simple::CGI->new();

my $mech = Test::WWW::Mechanize::HSS->new(
    server => $s,
);

$mech->get_ok('http://localhost/');
$mech->title_like(qr/Hello!/);