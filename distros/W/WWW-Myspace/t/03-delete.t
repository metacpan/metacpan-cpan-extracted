#!perl -T

use Test::More tests => 2;
#use Test::More 'no_plan';

use lib 't';
use TestConfig;

login_myspace or die "Login Failed - can't run tests";

my $myspace1 = $CONFIG->{'acct1'}->{'myspace'};
my $myspace2 = $CONFIG->{'acct2'}->{'myspace'};

SKIP: {

    TODO: { local $TODO = "delete_friend known to not be working due to myspace change";
        skip "Not logged in", 2 unless $CONFIG->{login};
        
        skip "Test friend not in friend list.", 2
            unless is_friend( $myspace1, $CONFIG->{'acct2'}->{'friend_id'} );
    
        ok( $myspace1->delete_friend( $CONFIG->{'acct2'}->{'friend_id'} ),
            'delete_friend returned true' );
    
        if ( is_friend( $myspace1, $CONFIG->{'acct2'}->{'friend_id'} ) ) {
            fail( 'Friend deleted' );
        } else {
            pass( 'Friend deleted' );
        }
    }
}

sub is_friend {

	my ( $myspace, $friend ) = @_;
	my @friends = $myspace->get_friends;

	my $pass=0;
	foreach my $id ( @friends ) {
		if ( $id == $friend ) {
			$pass=1;
		}
	}
	
	return $pass;

}