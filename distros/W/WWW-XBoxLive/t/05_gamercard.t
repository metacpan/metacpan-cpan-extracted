#!perl

use strict;
use warnings;

use Test::More tests => 12;

BEGIN { use_ok('WWW::XBoxLive::Gamercard'); }
require_ok('WWW::XBoxLive::Gamercard');

my $gamercard = new_ok(
    'WWW::XBoxLive::Gamercard',
    [
        gamertag => 'BrazenStraw3',
        name     => 'Andrew',
    ]
);

is( $gamercard->gamertag, 'BrazenStraw3' );
is( $gamercard->name,     'Andrew' );

# avatars
is( $gamercard->avatar_small,
    'http://avatar.xboxlive.com/avatar/BrazenStraw3/avatarpic-s.png' );
is( $gamercard->avatar_large,
    'http://avatar.xboxlive.com/avatar/BrazenStraw3/avatarpic-l.png' );
is( $gamercard->avatar_body,
    'http://avatar.xboxlive.com/avatar/BrazenStraw3/avatar-body.png' );

$gamercard = new_ok('WWW::XBoxLive::Gamercard');
ok( !$gamercard->avatar_small );
ok( !$gamercard->avatar_large );
ok( !$gamercard->avatar_body );
