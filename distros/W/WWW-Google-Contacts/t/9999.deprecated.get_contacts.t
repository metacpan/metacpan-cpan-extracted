#!perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;

use WWW::Google::Contacts;

SKIP: {
    if ( not $ENV{GOOGLE_USERNAME} or not $ENV{GOOGLE_PASSWORD} ) {
        skip
"You need to set env vars GOOGLE_USERNAME and GOOGLE_PASSWORD with appropriate values for this test",
          1;
    }
    ok( 1, "Credentials supplied" );

    my $google = WWW::Google::Contacts->new();
    $google->login( $ENV{GOOGLE_USERNAME}, $ENV{GOOGLE_PASSWORD} )
      or skip "Supplied credentials are invalid", 1;
    ok( 1, "Logged in to Google" );

    get_contacts($google);
}
done_testing();

sub get_contacts {
    my $google = shift;

    my @contacts = $google->get_contacts;
    my $contact  = shift @contacts;
    ok( defined $contact->{id},      "First contact has id" );
    ok( defined $contact->{updated}, "...and updated timestamp" );
    ok( exists $contact->{email},    "...email exists" );
    ok( exists $contact->{title},    "...title exists" );
}
