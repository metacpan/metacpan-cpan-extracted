#!/usr/bin/env perl
use strict;
use warnings;

use WWW::Google::Contacts;
use Test::More;

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

my $contacts = $google->contacts;
isa_ok( $contacts, 'WWW::Google::Contacts::ContactList' );

while ( my $contact = $contacts->next ) {
    isa_ok( $contact, 'WWW::Google::Contacts::Contact' );
}

note
'If you are seeing failures, make sure you have some contacts on your Google account to list!';

done_testing;
