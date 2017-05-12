#!perl -T

use strict;

use Data::Dumper;
use Test::More tests => 31;
#use Test::More 'no_plan';

use lib 't';
use TestConfig;

# This logs us in only if they have a local config file.
#login_myspace or die "Login Failed - can't run tests";

unless ( $CONFIG->{login} ) {
    diag "Running tests without login.  If you want to run the full test\n".
         "suite (not required), see the README file that came with the\n".
         "distribution.";
}

# Some setup
my $response;
my $attempts;
my @friends;

my $myspace;
my $myspace2;


# Offline tests -- no network access or login required

# Create an 'offline' WWW::Myspace object
$myspace = new WWW::Myspace( { auto_login => 0 } );
ok( ref $myspace, 'Create myspace object' );

my $get_login_forms_works = 1;

SKIP: {
    # Test _get_login_forms on an offline copy of a login form, to make sure
    #  the method works even if we don't have network access
    my $file = 't/login-forms/latest.html';
    if ( ! open INPUT, "<$file" )
    {
        warn "Unable to open file '$file':  $!";
        skip 'Failed to open file required for test', 1;
    }

    undef $/;
    my $form = <INPUT>;
    close INPUT;
    $/ = "\n";


    my @login_forms = $myspace->_get_login_forms( $form );
    my $num_login_forms = @login_forms;
    ok ( $num_login_forms == 1 ) or $get_login_forms_works = 0;
}

# Remove no-network-access marker file if it remains from a previous test run
unlink("no-network-access");

SKIP: {
    # See if we can get the homepage
    my $res = $myspace->get_page( 'http://www.myspace.com/' );
    if ( !defined $res || $myspace->error ) {

        # We failed to get the homepage
        warn $myspace->error;
        
        if ( $CONFIG->{login} ) {

            # If login tests have been configured, then we have a serious
            #  problem -- either network access is not working, or Myspace's
            #  homepage wasn't responding

            fail 'Get homepage';
            
            diag "There was a problem accessing the homepage.  Login tests\n".
                 " will still be run, but there is little chance of them\n".
                 " passing.  This could be a network issue or a problem with\n".
                 " MySpace.\n";

        } else {

            # Otherwise, it's likely that the testing machine just doesn't have
            #  network access.  Therefore, skip any tests which would normally
            #  fail as a result of this.  To do this, we create a 'marker' file
            #  named no-network-access.

            diag "Network access doesn't appear to be working.  Many tests\n".
                 " require network access so they must be skipped.\n";

            open ( FILE, '>no-network-access' );
            print FILE "This file indicates to WWW::Myspace's test suite\n".
                       " that network tests are not to be run.  It can be\n".
                       " safely removed.\n";
            close ( FILE );

        }

    } else {
        isa_ok ( $res, 'HTTP::Response', 'Get homepage' );
    }


    # Network tests.
    # All tests below require network access.
    skip 'Tests require network access', 29 if ( -f 'no-network-access' );


    # Make sure we received the US Myspace page and not any other localization
    my ( $localization ) = ( $res->decoded_content =~
        /header\/([a-z]{2}\-[A-Z]{2})\/mslogo/i );
    warn "Myspace seems to be serving pages to you in a language other than\n".
         " en-US, and this may break functionality where a WWW::Myspace\n".
         " object is used without logging into an account.  At present,\n".
         " Myspace uses IP-based geolocation and a workaround is attempted\n".
         " via the manipulation of cookies.  This error suggests that either\n".
         " the workaround no longer works, or there was possibly a problem\n".
         " connecting to the website.\n" unless
        is( lc ($localization), lc ('en-US'),
            'Homepage (without login) should display en-US localization' );


    SKIP: {
        # Make sure _get_login_forms worked when we tested it previously,
        #  because we need it here
        skip '_get_login_forms is possibly broken', 1
            if ( !$get_login_forms_works );
        skip "Didn't get homepage, needed for this test", 1
            if ( !defined $res );

        # Make sure we can find a login form on the homepage (which we've
        #  already downloaded)
        my @login_forms = $myspace->_get_login_forms( $res->decoded_content );
        my $num_login_forms = @login_forms;
        if ( $num_login_forms == 1 ) {
            pass( 'Found a single login form on homepage' );
        } elsif ( $num_login_forms > 1 ) {
            pass( 'Found multiple login forms on homepage' );
            warn 'More than one login form found on homepage\n';
        } else {
            fail( 'Found no login forms on homepage' );
            warn $myspace->error if $myspace->error;
        }
    }


    # Test is_band
    is( $myspace->is_band( 30204716 ), 1,
        "is_band identifies band profile correctly" );
    is( $myspace->is_band( $CONFIG->{'acct2'}->{'friend_id'} ), 0,
        "is_band identifies 3rd party non-band profile correctly" );
        
    #Test get_profile_type for individuals
    #76959716
    is( $myspace->get_profile_type( 123557), 1,
        "get_profile_type identifies personal profile correctly" );

    #Test get_profile_type for music
    is( $myspace->get_profile_type( 3327112), 2,
        "get_profile_type identifies music profile correctly" );
        
    #Test get_profile_type for film
    is( $myspace->get_profile_type( 198234322), 3,
        "get_profile_type identifies film profile correctly" );
        
    #Test get_profile_type for comedy
    is( $myspace->get_profile_type( 45202648), 4,
        "get_profile_type identifies comedy profile correctly" );

    is( $myspace->friend_user_name( $CONFIG->{'acct2'}->{'friend_id'} ),
        $CONFIG->{'acct2'}->{'user_name'}, 'Verify friend_user_name' );


    # Test friend_id method
    # 1. Check friend_id is returned when passed a link directly to the profile (eg. myspace.com/<friend_id>)
    is ($myspace->friend_id("48439059"), 48439059, "Get correct friend_id when passsed myspace.com/<friend_id>");

    # 2. check friend_id is returned by url
    is  ($myspace->friend_id("myspace.com/tomkerswill"), 7875748,
         "Get correct friend_id when passed custom URL.");

    # 3. check nothing is returned when passed just homepage
    #is ( $myspace->friend_id(""), "","Get when URL doesn't correspond to a profile");


    SKIP: {
        skip "Tests require login", 16 unless $CONFIG->{login};

        login_myspace or die "Failed to log into test acct1 - can't run tests";
        $myspace = $CONFIG->{'acct1'}->{'myspace'};
        isa_ok( $myspace, 'WWW::Myspace', 'Login to acct1' );

        $myspace2 = $CONFIG->{'acct2'}->{'myspace'};
        isa_ok( $myspace, 'WWW::Myspace', 'Login to acct2' );

        ok( $myspace->logged_in, "Login successful for acct1" );
        ok( $myspace2->logged_in, "Login successful for acct2" );


        # The following URL should display a 'logged in' version of the homepage
        $res = $myspace->get_page("http://www.myspace.com/");

        # Make sure we received the US Myspace page and not any other
        #  localization
        my ( $localization ) = ( $res->decoded_content =~
            /header\/([a-z]{2}\-[A-Z]{2})\/mslogo/i );
        warn "After logging into acct1, Myspace appears to serve pages to\n".
             " in a language other than than en-US, and this may break\n".
             " functionality where a WWW::Myspace object is used without\n".
             " logging into an account.  At present, this is configured in\n".
             " the Account Settings page for the account and WWW::Myspace\n".
             " can't currently override this automatically.\n" unless
            is( lc ($localization), lc ('en-US'),
                'Homepage (after login) should display en-US localization' );


        cmp_ok( $myspace->my_friend_id, '==', $CONFIG->{'acct1'}->{'friend_id'},
            'Verify friend ID' );

        is( $myspace->account_name, $CONFIG->{'acct1'}->{'username'},
            'Verify account_name' );

        is( $myspace->user_name, $CONFIG->{'acct1'}->{'user_name'},
            'Verify user_name' );

        # This should return more than 0 friends. If the regexp breaks,
        # this'll return something else, like undefined.
        cmp_ok( $myspace->friend_count, '>', 0, 'Check friend_count' );

        # Get friends
        @friends = $myspace->get_friends;

        ok( @friends, 'Retreived friend list' );

#       if ( @friends != 2 ) {
#           diag( 'Account has ' . @friends . ' friends' );
#       }

        # Check friends who emailed. We get messages from the other test account,
        # so this should be greater than 0.
        my @friends_who_emailed = $myspace->friends_who_emailed;
        cmp_ok( @friends_who_emailed, '>=', 0, 'Retreive friends who emailed' );


        # Get someone else's friends (same list, different method).
        my @other_friends =
            $myspace2->friends_from_profile( $CONFIG->{'acct1'}->{'friend_id'} );
        
        # If we're on the list, our "other_friends" list will be missing us,
        # so put us back in for testing.
        foreach my $id ( @friends ) {
            if ( $id == $CONFIG->{'acct2'}->{'friend_id'} ) {
                push( @other_friends, $id );
                # They have to be in numerical order to match.
                @other_friends = sort( @other_friends );
                last;
            }
        }
        
        @friends = sort @friends;
        # The friends and other_friends lists should be identical.
        # So first test the length

        # Disabled 10/10/07: Deleted friends show up when viewing your own friends,
        # but not when viewing as an "outsider". So this breaks.
        #is( @other_friends, @friends, 'Check friends_from_profile friend count');
        #diag( Dumper \@other_friends);
        #diag( Dumper \@friends);


        # Now check the elements
        SKIP: {
            skip "Friend count mismatch, won't test each element", 1 unless 
                ( @other_friends == @friends );
            my $friends_pass=1;
            for ( my $i = 0; $i < @friends; $i++ ) {
                unless ( $friends[$i] == $other_friends[$i] ) {
                    $friends_pass=0;
                    diag "Friend1: " . $friends[$i] . ", Friend2: " .
                        $other_friends[$i] . "\n";
                }
            }
            
            if ( $friends_pass ) {
                pass( 'Check friends_from_profile' )
            } else {
                fail( 'Check friends_from_profile' )
            }
        }

        # Count the friends in the test group. If we can get more than
        # 40 (first page) of friends we should be ok for the rest.?
        my @friends_in_group = $myspace->friends_in_group( $CONFIG->{'test_group'} );

        SKIP: {
            skip "friend_in_group disabled until it can be fixed due to myspace change.", 1;

            cmp_ok( @friends_in_group, '>', 41, 'Retreive friends in Perl Group' );
            diag( "Counted " . @friends_in_group . " friends in group" );
        }

        # Post a comment
        $response = $myspace->post_comment( $CONFIG->{'acct2'}->{'friend_id'},
            "Um, great profile..." );
        if ( ( $response =~ /^P/ ) || ( $response eq 'FC' ) ||
             ( $response eq "FF") ) { $response = 'P' }

        warn $myspace->error . "\n" if $myspace->error;
        is( $response, 'P', 'Post Comment' );

        # Test is_band logged in
        is( $myspace2->is_band, 0,
            "is_band identifies logged-in non-band profile correctly" );


        # Test get_birthdays
        my @bd = ( $myspace->get_birthdays );

        # We check for a friendID and a valid-looking month in the birthdate.
        # In case the test account has no birthdays, we'll pass too.
        ok( ( ! @bd ) || ( $bd[0] && ( $bd[1] =~ /Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec/ ) ),
            "get_birthday returned a friendID and valid-looking birthday" ) or
            warn "get_birthday got friendID " . $bd[0] . ", Bday: " . $bd[1] . " and ".
                 "returned " . @bd / 2 . " birthdays.\n";

    } # Tests requiring login

    # Test last_login
    if ( $CONFIG->{login} ) {
        cmp_ok ( $myspace->last_login( $CONFIG->{'acct2'}->{'friend_id'} ), ">",
                 time - 86400, "last_login date seems recent" );
    } else {
        ok ( $myspace->last_login( $CONFIG->{'acct2'}->{'friend_id'} ),
             "last_login returns a value" );

    }
    warn $myspace->error if $myspace->error;

} # Tests requiring network access
