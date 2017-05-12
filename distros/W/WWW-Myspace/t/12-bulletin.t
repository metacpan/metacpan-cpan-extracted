#!perl -T

use Test::More tests => 1;
#use Test::More 'no_plan';

use lib 't';
use TestConfig;
login_myspace or die "Login Failed - can't run tests";

my $myspace = $CONFIG->{acct1}->{myspace}; # For sanity

my $ident = "wmyw" . int(rand(100000)) . "wmyw";

SKIP: {
	skip "Not logged in", 1 unless $CONFIG->{login};

#    TODO: { local $TODO = "post_bulletin needs to be updated to work with current form";
        my $testing=1; $testing=0 if ( $CONFIG->{fulltest} );

        my $result = $myspace->post_bulletin(
                subject => "Testing $ident",
                message => "Hi there $ident, sorry if you got this.",
                testing => $testing,
            );
        
        if ( $myspace->error ) {
            warn $myspace->error . "\n";
    #		warn "\n\n".$myspace->current_page->content;
        }
        
        ok( $result, "post_bulletin returns positive success code" );
#    }
}