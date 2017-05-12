use Test::More tests => 3;

use_ok('WWW::Mechanize');
use_ok('WWW::Mechanize::Plugin::Display');

my $mech = WWW::Mechanize->new();
ok($mech->can('display'), "display method was added to object");

