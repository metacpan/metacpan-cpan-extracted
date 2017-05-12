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
    foreach my $member ( @{ $g->member } ) {
        is( defined $member->full_name,
            1, "Member got full name [" . $member->full_name . "]" );

        my $email = $member->email->[0];
        ok( defined $email, "...got an email address [" . $email->value . "]" );
        my $type    = $email->type->name;
        my $newtype = 'work';
        if ( $type eq 'work' ) {
            $newtype = 'home';
        }
        $email->type($newtype);
        $member->update;

        # If we fetch again instantly, we don't get the updated record :-/
        sleep 5;

        # Now fetch this user again and ensure type has been updated
        my $update    = $google->contact( $member->id );
        my $upd_email = $update->email->[0];
        ok( defined $upd_email, "Updated user got email" );
        is( $upd_email->type->name, $newtype, "...correct (updated) type" );
        is( $upd_email->label, $newtype, "...and label got the same value" );

        # Now change to a custom type

        $upd_email->type('spamhaus');
        $update->update;

        # If we fetch again instantly, we don't get the updated record :-/
        sleep 5;

        # Fetch this user again and ensure type has been updated
        $update    = $google->contact( $member->id );
        $upd_email = $update->email->[0];

        ok( defined $upd_email, "Updated user got email" );
        is( $upd_email->label, 'spamhaus', "...correct label" );
        is( $upd_email->type->name,
            'spamhaus', "...type name is also same value" );
    }
}

done_testing;
