#!/usr/bin/perl
use strict; use warnings;
use lib qw/ lib t /;

use Test::More tests => 6;
use MyMechanize;
my $mech = MyMechanize->new;

is( $mech->my_mech_load_files( glob("t/webpages/*.yml") ), 8, 'load all test pages' );

my $res;
isa_ok( $res = $mech->get( "http://test/home.html" ), 'HTTP::Response' );
is( $res->code, 200, 'response code' );
is( $res->base, 'http://test/home.html', 'base' );
is( $res->content_type, 'text/html', 'content type' );
ok( $res->is_success, 'success!' );
