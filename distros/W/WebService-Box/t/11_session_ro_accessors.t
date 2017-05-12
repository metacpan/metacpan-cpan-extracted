#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use WebService::Box;
use WebService::Box::Session;

my $box = WebService::Box::Session->new(
    client_id     => 123,
    client_secret => 'abcdef',
    refresh_token => 'affe0815',
    redirect_uri  => 'http://localhost',
    box           => WebService::Box->new,
);

my ($before,$after) = (""," is a read-only accessor");
if ( $INC{"Class/XSAccessor.pm"} ) {
    $before = "Usage: WebService::Box::Session::";
    $after  = '\(self\)';
}

for my $method ( qw/box client_id client_secret refresh_token redirect_uri auth_token expires/ ) {
    throws_ok
        { $box->$method( 'test' ) }
        qr/$before$method$after/,
        $method . ' is a read-only accessor';
}

throws_ok
    { $box->auth_client( 'test' ) }
    qr/auth_client is a read-only accessor/,
    'auth_client is a read-only accessor';

done_testing();
