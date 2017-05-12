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

    my $google = WWW::Google::Contacts->new( debug => 1 );
    $google->login( $ENV{GOOGLE_USERNAME}, $ENV{GOOGLE_PASSWORD} )
      or skip "Supplied credentials are invalid", 1;
    ok( 1, "Logged in to Google" );

    get_contact($google);
}
done_testing();

sub get_contact {
    my $google = shift;

    # TODO - fix so it works for other than me :)
    my $id      = 'http://www.google.com/m8/feeds/contacts/default/base/21';
    my $contact = $google->get_contact($id);
    ok( defined $contact->{id},      "First contact has id" );
    ok( defined $contact->{updated}, "...and updated timestamp" );
    ok( exists $contact->{email},    "...email exists" );
    ok( exists $contact->{title},    "...title exists" );
}
