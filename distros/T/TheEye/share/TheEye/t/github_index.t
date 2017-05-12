#!perl -T

use 5.010;
use Test::More tests => 4;
use Test::WWW::Mechanize;

my $mech = Test::WWW::Mechanize->new;
$mech->get_ok('https://github.com/');
$mech->base_is('https://github.com/');
$mech->content_contains("git");
1;
