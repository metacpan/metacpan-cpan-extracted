#!perl -T

#use Test::More 'no_plan';
use Test::More tests => 16;
use strict;

use WWW::Myspace;

use lib 't';
use TestConfig;


my $note_third_party_profile =
    "This test acts on a 3rd-party profile which we do not control;  a test\n".
    "failure here does not necessarily mean that something is broken.";


# Get myspace object
my $myspace = new WWW::Myspace( auto_login => 0 );

# :FIXME: want to clear current_page here

ok ( !defined $myspace->last_login_ymd,
     'last_login_ymd without parameters, with a blank current_page' );
ok ( !defined $myspace->last_login,
     'last_login without parameters, with a blank current_page' );


SKIP: {

    # Network tests.
    # All tests below require network access.
    skip 'Tests require network access', 14 if ( -f 'no-network-access' );


    SKIP: {
        # Load any working profile using ID or URL
        my $friend_id = "greatbigseaofficial";

        my $profile = $myspace->get_profile( $friend_id )
            or skip 'Could not load a profile which these tests depends upon',
                    6;

        my $last_login_ymd = $myspace->last_login_ymd;
        my $last_login = $myspace->last_login;

        ok ( defined $last_login_ymd,
             'last_login_ymd without parameters' );
        ok ( defined $last_login,
             'last_login without parameters' );

        # :FIXME: want to clear current_page here

        is ( $myspace->last_login_ymd( undef ),
             $last_login_ymd,
             "last_login_ymd passing 'undef' as a parameter" );
        is ( $myspace->last_login( undef ),
             $last_login,
             "last_login passing 'undef' as a parameter" );

        # :FIXME: want to clear current_page here

        # Test both functions with a page parameter;  should return the same
        #  results
        is ( $myspace->last_login_ymd( page => $profile ),
             $last_login_ymd,
             "last_login_ymd using 'page' parameter" );
        is ( $myspace->last_login( page => $profile ),
             $last_login,
             "last_login using 'page' parameter" );

       # Test both functions using the friend_id parameter;  should return the
       #  same results
        is ( $myspace->last_login_ymd( friend_id => $friend_id ),
             $last_login_ymd,
             "last_login_ymd using 'friend_id' parameter" );
        is ( $myspace->last_login( friend_id => $friend_id ),
             $last_login,
             "last_login using 'friend_id' parameter" );
    }


    # Try to get the last login date of this deleted profile
    # Should return undefined, not zero or any other valid date value
    # :FIXME: very slow at the moment;  does the deleted profile cause retries?
    my $deleted_friend_id = 1000000;

    ok ( !defined $myspace->last_login_ymd( $deleted_friend_id ),
         'last_login_ymd date of a deleted profile should return undefined' );

    ok ( !defined $myspace->last_login( $deleted_friend_id ),
         'last_login date of a deleted profile should return undefined' );


    # Try to get the last login date of this personal profile
    my $friend_id = 2114443;

    # Teddy doesn't log in very often (and I also have no idea who he is)
    my $expected_last_login_ymd = "2004-05-31";
    my $expected_last_login = 1085961600;   # UNIX date for 2004-05-31T00:00:00Z


    # Test return value of last_login_ymd
    my $last_login_ymd = $myspace->last_login_ymd( $friend_id );

    ok ( $last_login_ymd eq $expected_last_login_ymd,
         "last_login_ymd for profile $friend_id\n".
         "         got: '$last_login_ymd'\n".
         "    expected: '$expected_last_login_ymd'" )
        or diag $note_third_party_profile;


    # Test return value of last_login
    my $last_login = $myspace->last_login( $friend_id );

    is ( $last_login, $expected_last_login,
         "last_login for profile $friend_id" )
        or diag $note_third_party_profile;



    # Try to get the last login date of this music profile
    my $band_friend_id = 26348118;

    # They don't log in very often, I'm guessing they didn't have many fans
    $expected_last_login_ymd = "2005-11-04";
    $expected_last_login = 1131062400;   # UNIX date for 2005-04-11T00:00:00Z


    # Test return value of last_login_ymd
    $last_login_ymd = $myspace->last_login_ymd( $band_friend_id );

    ok ( $last_login_ymd eq $expected_last_login_ymd,
         "last_login_ymd for profile $band_friend_id\n".
         "         got: '$last_login_ymd'\n".
         "    expected: '$expected_last_login_ymd'" )
        or diag $note_third_party_profile;


    # Test return value of last_login
    $last_login = $myspace->last_login( $band_friend_id );

    is ( $last_login, $expected_last_login,
         "last_login for profile $band_friend_id" )
        or diag $note_third_party_profile;

}
