#!perl -T

#use Test::More 'no_plan';
use Test::More tests => 5;
use strict;

use WWW::Myspace;

use lib 't';
use TestConfig;
#login_myspace or die "Login Failed - can't run tests";

# Get myspace object
my $myspace = new WWW::Myspace( auto_login => 0 );


my $note_third_party_profile =
    "This test acts on a 3rd-party profile which we do not control;  a test\n".
    "failure here does not necessarily mean that something is broken.";


# Try to find an account which doesn't exist
my @results = $myspace->find_friend( 'madeup@example.com' );
if ( $myspace->error )
{
    warn $myspace->error;
    fail "find_friend failed for 'madeup\@example.com'";
} else {
    is ( scalar @results, 0, 'Search for a non-existent friend' );
}


# Try to find an account that should exist
# This account seems to have existed for over 4 years
SKIP: {
    my $email = 'email@address.com';

    my @results = $myspace->find_friend( $email );
    if ( $myspace->error ) {
        warn $myspace->error;
        fail "find_friend failed for '$email'";
        skip 'find_friend failed', 1;
    }

    # This search should find only 1 result
    is ( scalar @results, 1,
         "find_friend for '$email' should find exactly 1 result" )
        or diag $note_third_party_profile;

    is ( $results[0], 2114443,
         "find_friend for '$email'" )
        or diag $note_third_party_profile;
}


# Search for acct2's email address
SKIP: {
    skip "acct2 not configured", 2
        unless defined $CONFIG->{acct2}->{friend_id}
            && defined $CONFIG->{acct2}->{username};

    my @results = $myspace->find_friend( $CONFIG->{acct2}->{username} );
    if ( $myspace->error ) {
        warn $myspace->error;
        fail "find_friend failed for '$CONFIG->{acct2}->{username}'";
        skip 'find_friend failed', 1;
    }


    # If the search finds more than one match, it may cause the following test
    #  to fail, so we need to check for this.
    
    if ( scalar @results == 0 )
    {

        skip "find_friend for acct2 found no results -- but Myspace's new\n".
             "search engine seems to have some records missing so this is\n".
             "probably not a bug", 2;

    } elsif ( scalar @results > 1)
    {

        skip "find_friend found more matches than expected -- this is\n".
             "probably not a bug", 2;

    } else {

        is ( scalar @results, 1,
             "find_friend with acct2's email address should find exactly one\n".
             "match" );
        is ( $results[0], $CONFIG->{acct2}->{friend_id},
             "find_friend should be able to find acct2" );

    }
}
