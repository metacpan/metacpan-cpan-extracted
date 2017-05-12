#!perl
use strict;
use warnings;
use lib 'lib';
use Test::More tests => 5;
use lib 't/lib';
use Test::WWW::Mechanize::Catalyst 'Catty';

my $root = "http://localhost";

my $m = Test::WWW::Mechanize::Catalyst->new;
$m->credentials( 'user', 'pass' );

$m->get_ok("$root/check_auth_basic/");
is( $m->ct,     "text/html" );
is( $m->status, 200 );

$m->credentials( 'boofar', 'pass' );

$m->get("$root/check_auth_basic/");
is( $m->ct,     "text/html" );
is( $m->status, 401 );

