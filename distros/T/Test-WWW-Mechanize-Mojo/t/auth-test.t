#!perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Mojo;
use Test::WWW::Mechanize::Mojo;

use lib './t/lib';
require MyMojjy;

my $t = Test::Mojo->new();

my $root = "http://localhost";

my $m = Test::WWW::Mechanize::Mojo->new(tester => $t);
$m->credentials( 'user', 'pass' );

$m->get_ok("$root/check_auth_basic/");
is( $m->ct,     "text/html" );
is( $m->status, 200 );

$m->credentials( 'boofar', 'pass' );

$m->get("$root/check_auth_basic/");
is( $m->ct,     "text/html" );
is( $m->status, 401 );

