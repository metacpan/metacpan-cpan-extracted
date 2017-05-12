#!perl -T

use Test::More tests => 2;
#use Test::More 'no_plan';

use lib 't';
use TestConfig;
login_myspace or die "Login Failed - can't run tests";

my $myspace = $CONFIG->{acct1}->{myspace}; # For sanity

SKIP: {
    skip "Not logged in", 2 unless $CONFIG->{login};

    # Get a list of photo IDs
    #warn "Getting photos for $CONFIG->{acct1}->{friend_id}\n";
    my @photo_ids = $myspace->get_photo_ids(
            friend_id => $CONFIG->{acct1}->{friend_id}
        );
    warn $myspace->error if $myspace->error;
    
    my ( %friend_ids ) = ();
    my $pass = 1;
    foreach my $id ( @photo_ids ) {
        if ( $friend_ids{ $id } ) {
            $pass=0;
            warn "Found duplicate photo ID $id\n";
        } else {
            $friend_ids{ $id }++;
            warn "Got photoID $id\n";
        }
    }
    
    # Can't really test 'cause the test account may not have any photos.
    # ok( ( @photo_ids || ( @photo_ids == 0 ) ),
    #         'get_photo_ids returned at least one photo' );
    
    # Check for duplicates
    ok( $pass, 'No duplicate IDs found' );


    # Try to set the default photo.
    skip "Need more than 1 photo", 1 unless ( @photo_ids > 1 );

    # Toggle the default photo between #1 and #2.
    ok( (
            $myspace->set_default_photo( photo_id => $photo_ids[ 0 ] ) ||
            $myspace->set_default_photo( photo_id => $photo_ids[ 1 ] )
        ),
        'set_default_photo'
      );
    warn $myspace->error if $myspace->error;

}
