#!perl -T

#use Test::More 'no_plan';
use Test::More tests => 6;
use strict;

use WWW::Myspace;

use lib 't';
use TestConfig;


my $note_third_party_profile =
    "This test acts on a 3rd-party profile which we do not control;  a test\n".
    "failure here does not necessarily mean that something is broken.";


# Get myspace object
my $myspace = new WWW::Myspace( auto_login => 0 );

SKIP: {

    # Network tests.
    # All tests below require network access.
    skip 'Tests require network access', 6 if ( -f 'no-network-access' );


    # Teddy, whoever that is
    my $friend_id1 = 2114443;

    # Has no friends other than Tom
    # Method should return zero (zero friends other than Tom) -- *not* undef
    my @friends1 =
        $myspace->get_friends( source => 'profile', id => $friend_id1 );

    warn $myspace->error if $myspace->error;
    ok ( ! $myspace->error,
         'get_friends should not set $myspace->error for this profile' );

    is ( scalar @friends1, 0, 'Teddy has no friends' )
        or diag $note_third_party_profile;


    # Some private profile
    my $friend_id2 = 12471079;

    # get_friends should return undef and set $myspace->error
    my $friends2 =
        $myspace->get_friends( source => 'profile', id => $friend_id2 );

    ok ( $myspace->error,
         'get_friends should set $myspace->error for private profile' )
        or diag $note_third_party_profile;

    is ( $friends2, undef,
         'get_friends should return undef for private profile' )
        or diag $note_third_party_profile;


    # Some unpopular band
    my $friend_id3 = 26348118;

    # Expect them to have at least one friend other than Tom (currently 7 as of
    #  2008-08-25, but it might go down a bit)
    my @friends3 =
        $myspace->get_friends( source => 'profile', id => $friend_id3 );

    warn $myspace->error if $myspace->error;
    ok ( ! $myspace->error,
         'get_friends should not set $myspace->error for this profile' );

    ok ( scalar @friends3 >= 1, 'Band profile has some friends' )
        or diag $note_third_party_profile;

}
