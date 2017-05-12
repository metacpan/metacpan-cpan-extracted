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

    $member->language(
        {
            code => "en-US",
        }
    );
    $member->update;

    # If we fetch again instantly, we don't get the updated record :-/
    sleep 5;

    # Now fetch this user again and ensure data is valid
    $member = $google->contact( $member->id );
    my $lang = $member->language->[0];
    ok( defined $lang, "Updated user got language" );
    is( $lang->code, "en-US", "...correct code" );

    $member->language(
        {
            label => "Swedish",
        }
    );
    $member->update;

    # If we fetch again instantly, we don't get the updated record :-/
    sleep 5;
    $member = $google->contact( $member->id );
    $lang   = $member->language->[0];
    ok( defined $lang, "Updated user got language" );
    is( $lang->label, "Swedish", "...correct label" );

    $member->language(undef);
    $member->update;

    # If we fetch again instantly, we don't get the updated record :-/
    sleep 5;

    # Now fetch this user again and ensure data is valid
    $member = $google->contact( $member->id );
    $lang   = $member->language;
    ok( !defined $lang, "Updated user got no language" );
}

done_testing;
