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

    $member->organization(
        {
            department      => "IT",
            job_description => "Code monkey",
            name            => "Work",
            symbol          => "W",
            title           => "Coder",
            where           => "London",
        }
    );
    $member->update;

    # If we fetch again instantly, we don't get the updated record :-/
    sleep 5;

    # Now fetch this user again and ensure data is valid
    my $update = $google->contact( $member->id );
    my $org    = $update->organization->[0];
    ok( defined $org, "Updated user got organization" );
    is( $org->department,   "IT",     "...correct department" );
    is( $org->where->value, "London", "...correct where" );

    $member = $update;

    $member->organization(undef);
    $member->update;

    # If we fetch again instantly, we don't get the updated record :-/
    sleep 5;

    # Now fetch this user again and ensure data is valid
    $update = $google->contact( $member->id );
    $org    = $update->organization;
    ok( !defined $org, "Updated user got no organization" );
}

done_testing;
