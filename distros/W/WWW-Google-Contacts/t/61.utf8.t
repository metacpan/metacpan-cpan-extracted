#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

## NOTE -- This test relies on you having a couple of very specific users in your google account
# One group called "Test group", with at least one member
## NOTE -- it will overwrite Email values for contacts in this Test group

# quite far from a unit test, but needs the google integration for the proper testing :(

# Ideally I'd use something like LWP::UserAgent::Mockable, but I then need to have all the data anonimized

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
        ok utf8::is_utf8( $member->full_name ), "full_name is utf8";
        my $new_val = 'xfoobar@piña.coláda☃snowman.com';
        $member->email($new_val);

        $member->update;
        is( 1, 1, "Updated contact" );
        last;
    }
}

@groups = $google->groups->search( { title => "Test group" } );
foreach my $g (@groups) {
    is( scalar @{ $g->member } > 0, 1, "Test group still got members" );
    foreach my $member ( @{ $g->member } ) {
        my $email   = $member->email->[0];
        my $new_val = 'xfoobar@piña.coláda☃snowman.com';
        is( $email->value, $new_val, "Email address looks right" );
        ok( utf8::is_utf8( $email->value ), "..and it's utf8" );
        last;
    }
}

done_testing;
