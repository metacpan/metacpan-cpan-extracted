#!perl -T

use Test::More tests => 2;
#use Test::More 'no_plan';

use lib 't';
use TestConfig;

login_myspace or die "Login Failed - can't run tests";

my $myspace1 = $CONFIG->{'acct1'}->{'myspace'};
my $myspace2 = $CONFIG->{'acct2'}->{'myspace'};

# Generate "random" seed.
my $ident = "wmyw" . int(rand(100000)) . "wmyw";
my ( @friends, $res );

SKIP: {
	skip "Not logged in", 2 unless $CONFIG->{login};
	
	# Try to approve friend requests for acct1
	#warn "Approving friend requests for acct1\n";
	@friends = $myspace1->approve_friend_requests( "Thanks for the add!\n\n${ident}" );
	
	# If there was a friend (or more) approved, pass.
	if ( @friends ) {
		pass( 'Approve friends' )
	} else { # Otherwise,
	    TODO: { local $TODO = "delete_friend method disabled";
            # From acct2, delete acct1 as a friend.
            warn "Deleting acct2 as a friend\n";
            $myspace1->delete_friend( $CONFIG->{'acct2'}->{'friend_id'} );
            warn $myspace1->error."\n" if $myspace1->error;
        
            # Then send a friend request.
            # This generates "use of initialized value" warnings from
            # HTTP::Request::Form.
            warn "Sending friend request from acct2 to acct1\n";
        #	warn 'Ignore the following "Use of uninitialized value" errors'."\n";
            $myspace2->send_friend_request( $CONFIG->{'acct1'}->{'friend_id'} );
            warn $myspace2->error."\n" if $myspace2->error;
        
            # Now try to approve friend requests.
            warn "Approving friend request\n";
            @friends = $myspace1->approve_friend_requests( "Thanks for the add!\n\n${ident}" );
        
            # If we approved someone, pass. otherwise, fail.
            if ( @friends ) {
                pass( 'Approve friends' );
            } else {
                fail( 'Approve friends' );
            }
        }
	}
	
	SKIP: {
	
	    TODO: { local $TODO = "comment post test unreliable until delete_friends is working";
            # Now see if we posted that comment.
            warn "Checking for comment post using friendID " .
                $CONFIG->{'acct2'}->{'friend_id'} .
                " and ident " . $ident . "\n";
            $res = $myspace1->get_profile( $CONFIG->{'acct2'}->{'friend_id'} );
            
            # Don't try this at home.  If we find it, fine, but if not,
            # we check to see if we got a CATPCHA response, and skip the test
            # if we did.
            if ( $res->content =~ /${ident}/ ) {
                pass( 'approve_friend_requests posted comment' );
            } else {
                skip "Comment reported CAPTCHA, skipping approval comment verify\n", 1
                    if ( $myspace1->captcha );
                fail( 'approve_friend_requests posted comment' );
            }
        }
	}

}