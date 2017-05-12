#!/usr/bin/env perl
use strict;
use warnings;

# INTEGRATION TEST

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

    $member->relation(
        {
            label => 'sister',
            value => 'Berit',
        }
    );
    $member->update;

    # If we fetch again instantly, we don't get the updated record :-/
    sleep 5;

    # Now fetch this user again and ensure data is valid
    $member = $google->contact( $member->id );
    my $rel = $member->relation->[0];
    ok( defined $rel, "Updated user got relation" );
    is( $rel->type->name, "sister", "...correct type" );
    is( $rel->value,      "Berit",  "...correct value" );
    $rel->label('Spammer');
    $member->update;

    # If we fetch again instantly, we don't get the updated record :-/
    sleep 5;
    $member = $google->contact( $member->id );
    $rel    = $member->relation->[0];
    ok( defined $rel, "Updated user got relation" );
    is( $rel->label, "Spammer", "...correct label" );
    is( $rel->value, "Berit",   "...correct value" );

    $member->relation(undef);
    $member->update;

    # If we fetch again instantly, we don't get the updated record :-/
    sleep 5;

    # Now fetch this user again and ensure data is valid
    $member = $google->contact( $member->id );
    $rel    = $member->relation;
    ok( !defined $rel, "Updated user got no relations" );
}

done_testing;
