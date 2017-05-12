use strict;
use warnings;

use Test::More;
use lib 't/lib';

BEGIN {
    eval {
        require Catalyst::Plugin::Session;
        require Catalyst::Plugin::Session::State::Cookie;
    };

    if ($@) {
        diag($@);
        plan skip_all => "Need Catalyst::Plugin::Session to run this test";
        exit 0;
    }
}

use Test::WWW::Mechanize::Catalyst;

plan tests => 4;

my $m1 = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'Catty');
my $m2 = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'CattySession');

$m1->get_ok("/name");
$m1->title_is('Catty');

$m2->get_ok("/name");
$m2->title_is('CattySession');
