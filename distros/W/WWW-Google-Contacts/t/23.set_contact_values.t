#!/usr/bin/env perl
use strict;
use warnings;

## NOTE -- This test relies on you having specific data in your google account
# One group called "Test group", with at least one member

use WWW::Google::Contacts;
use Test::More;
use Data::Dumper;

my $username = $ENV{TEST_GOOGLE_USERNAME};
my $password = $ENV{TEST_GOOGLE_PASSWORD};

plan skip_all =>
  'no TEST_GOOGLE_USERNAME or TEST_GOOGLE_PASSWORD set in the environment'
  unless $username and $password;

my $google = WWW::Google::Contacts->new(
    username => $username,
    password => $password,
    protocol => "https"
);
isa_ok( $google, 'WWW::Google::Contacts' );

my @groups = $google->groups->search( { title => "Test group" } );
foreach my $g (@groups) {
    is( scalar @{ $g->member } > 0, 1, "Test group got members" );
    my $member = $g->member->[0];

    my ( $update, $update2, $addr, $web, $gender );

    $member->postal_address(
        {
            street   => "Somestreet " . int( rand(100) ),
            city     => "London",
            postcode => '',
            country  => {
                code => "NO",
                name => "Norway",
            },
        }
    );

    $member->website(
        {
            type  => 'blog',
            value => 'http://blah.blog.org/',
        }
    );

    $member->gender("male");

    $member->update;

    # If we fetch again instantly, we don't get the updated record :-/
    sleep 5;

    # Now fetch this user again and ensure data is valid
    $update = $google->contact( $member->id );
    $addr   = $update->postal_address->[0];
    ok( defined $addr, "Updated user got postal address" );
    is( $addr->city,          "London", "...correct city" );
    is( $addr->type->name,    "home",   "...got the default type" );
    is( $addr->country->name, "Norway", "...got correct country" );
    is( $addr->country->code, "NO",     "...and correct country code" );

    $web = $update->website->[0];
    ok( defined $web, "Updated user got website" );
    is( $web->type, "blog", "...correct type" );
    is( $web->value, 'http://blah.blog.org/', "...correct value" );

    is( $update->gender->value, "male", "...correct gender value = male" );

    $update->postal_address(
        {
            street  => "Somestreet " . int( rand(100) ),
            city    => "Londonx",
            type    => '',
            country => "Sweden",
        }
    );

    $update->add_website(
        {
            type  => "work",
            value => "http://work.com",
        }
    );

    $update->sensitivity("private");
    $update->gender("female");
    $update->update;

    # If we fetch again instantly, we don't get the updated record :-/
    sleep 5;

    # Now fetch this user again and ensure data is valid
    $update = $google->contact( $member->id );
    $addr   = $update->postal_address->[0];
    ok( defined $addr, "Updated user got postal address" );
    is( $addr->city,          "Londonx", "...correct city" );
    is( $addr->type->name,    "home",    "...got the default type" );
    is( $addr->country->name, "Sweden",  "...got correct country" );
    is( $addr->country->code, undef,     "...and no country code, correct" );

    is( $update->sensitivity->type,
        "private", "...correct sensitivity = private" );

    $web = $update->website;
    is( scalar @{$web},         2,        "Got 2 websites now" );
    is( $update->gender->value, "female", "...correct gender value = female" );

    $update->website("http://something.com");
    $update->sensitivity("normal");

    # 2nd update
    $update->update;

    # If we fetch again instantly, we don't get the updated record :-/
    sleep 5;
    $update2 = $google->contact( $member->id );

    $web = $update2->website;
    is( scalar @{$web}, 1, "Got 1 website now" );
    $web = $update2->website->[0];
    is( $web->type, 'home', "...with correct (default) type" );
    is( $web->value, 'http://something.com', "...and correct value" );
    is( $update->sensitivity->type,
        "normal", "...correct sensitivity = normal" );
}

done_testing;
