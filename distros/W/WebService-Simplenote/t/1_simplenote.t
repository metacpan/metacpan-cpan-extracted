#!/usr/bin/env perl -w

use Test::More;
use WebService::Simplenote;

if ( !defined $ENV{SIMPLENOTE_USER} ) {
    plan skip_all => 'Set SIMPLENOTE_USER and SIMPLENOTE_PASS for remote tests';
} else {
    plan tests => 4;
}

my $sn = WebService::Simplenote->new(
    email    => $ENV{SIMPLENOTE_USER},
    password => $ENV{SIMPLENOTE_PASS}
);

ok( defined $sn,                          'new() returns something' );
ok( $sn->isa( 'WebService::Simplenote' ), '... the correct class' );

ok( $sn->_login, 'log in and get auth token' );

ok( my $remote_index = $sn->get_remote_index, 'list remote notes' );

