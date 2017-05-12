#!perl

use strict;
use warnings;

use Test::More tests => 5;

BEGIN { use_ok('WWW::XBoxLive::Game'); }
require_ok('WWW::XBoxLive::Game');

my $profile = new_ok(
    'WWW::XBoxLive::Game',
    [
        title               => 'Fifa 12',
        percentage_complete => '50',
    ]
);

is( $profile->title,               'Fifa 12' );
is( $profile->percentage_complete, '50' );
