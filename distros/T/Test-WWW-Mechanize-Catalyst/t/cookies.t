#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More;

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
use lib 't/lib';
use Test::WWW::Mechanize::Catalyst 'CattySession';

plan tests => 3;

my $m = Test::WWW::Mechanize::Catalyst->new;
$m->credentials( 'user', 'pass' );

$m->get_ok("/");
$m->title_is("Root");

is( $m->status, 200 );
