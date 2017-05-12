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
  SKIP: {
        $google->login( $ENV{GOOGLE_USERNAME}, $ENV{GOOGLE_PASSWORD} )
          or skip "Supplied credentials are invalid", 1;
        ok( 1, "Logged in to Google" );

        get_groups($google);
    }
}
done_testing();

sub get_groups {
    my $google = shift;

    my @groups = $google->get_groups;
    my $group  = shift @groups;
    ok( defined $group->{id},      "First contact has id" );
    ok( defined $group->{updated}, "...and updated timestamp" );
    ok( exists $group->{title},    "...title exists" );
}

1;
