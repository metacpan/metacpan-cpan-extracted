#!/usr/bin/perl
use strict;
use warnings;
use WebService::HabitRPG;
use Config::Tiny;
use Test::More;

if (not $ENV{RELEASE_TESTING}) {
    plan skip_all => "Release only tests... skipping";
}

my $config = Config::Tiny->read( "$ENV{HOME}/.habitrpgrc" );

if (not $config->{auth}{testing}) {
    plan skip_all => "Online testing uses the author's account";
}

my $hrpg = WebService::HabitRPG->new(
    api_token => $config->{auth}{api_token},
    user_id   => $config->{auth}{user_id},
);

my $user = $hrpg->user;

is( $user->{profile}{name}, q{Paul '@pjf' Fenwick} );

SKIP: {
    skip "User profiles have changed upstream", 1;

    # The user object no longer has a 'tasks' key. The internal
    # format has changed. Luckily, this doesn't seem to have caused
    # the rest of our code to break, because we rarely access the
    # user object except for status.

    is( $user->{tasks}{'c343fb63-f978-4d73-b8d8-7cb48f01e415'}{text},
        "Laptop backup" );
}

like( $user->{stats}{maxHealth}, qr/^\d+$/, "MaxHealth" );

done_testing;
