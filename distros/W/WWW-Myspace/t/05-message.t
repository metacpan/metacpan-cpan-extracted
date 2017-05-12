#!perl -T
#---------------------------------------------------------------------
# Test Message.pm
# $Id: 05-message.t,v 1.1 2006/02/28 09:40:04 grant Exp $

use Test::More tests => 26;
#use Test::More 'no_plan';

use lib 't';
use TestConfig;
use WWW::Myspace::Message;

login_myspace or die "Login Failed - can't run tests";

SKIP: {

    skip "Not logged in", 13 unless $CONFIG->{login};

    # Sanity
    my $myspace1 = $CONFIG->{acct1}->{myspace};
    my $myspace2 = $CONFIG->{acct2}->{myspace};

    # Generate "random" identity tag.
    my $ident = "wmyw" . int(rand(100000)) . "wmyw";
        diag "Sending a message containing the string '$ident'\n";

    # First test the send_message method in WWW::Myspace
    # Send a message
    $response = "";
    $response = $myspace1->send_message(
        $CONFIG->{'acct2'}->{'friend_id'},
        "Hi ". $ident, 'Just saying hi.\n\n'.
        'Hope all is well.' );

        # If a CAPTCHA is found, we should skip the test rather than pass or fail it
        if ( $response eq 'FC' ) {
            diag "A CAPTCHA response was requested;  some tests can therefore not\n".
                 " run.  Consider logging into the test acct1, sending a message,\n".
                 " and completing the CAPTCHA when prompted.  Then try re-running \n".
                 " these tests.\n";
            skip "A CAPTCHA response was requested", 13;
        }

    warn $myspace1->error if $myspace1->error;
    is( $response, 'P', 'Send Message' );

    # Use get_inbox to find the message. We just sent it, so we just
    # check the 1st 2 pages of messages for speed (and to make sure we
    # can get to the 2nd page).
    my $inbox = $myspace2->get_inbox( end_page => 2);
    my @messages = @{$inbox};

    # Check contents
    my $msgcnt = @{$inbox};
        diag "Inbox contains at least $msgcnt messages\n";

    cmp_ok( $msgcnt, ">", 0, "Inbox has contents" );
    diag "get_inbox may not be reading second page. Got $msgcnt messages."
        unless ( $msgcnt > 10 );

    like( $inbox->[0]->{message_id}, qr/^[0-9]+$/,
        "Inbox has a valid message ID in first slot" );

    # Go find the message we sent
    my $msg = {};
    my %msg = ();
    my $found_message = 0;
    foreach $msg ( @messages ) {
        diag( "Found message: " . $msg->{subject} . ", ID: " . $msg->{message_id} );

        if ( $msg->{subject} =~ /$ident/ ) {
            $found_message = 1;
            # Dereference it so we can keep it.
            %msg = %{ $msg };
            last;
        }
    }

    ok( $found_message, 'Found sent message');

    SKIP: {
        skip "Found message failed", 9 unless $found_message;

    #   diag( 'Found message_id: ' . $msg{message_id} );

        like( $msg{message_id}, qr/^[0-9]+$/, "Found the test message we sent" );

        # Check the values from inbox
        is( $msg{sender}, $CONFIG->{acct1}->{friend_id}, 'inbox sender friend_id' );
        is( $msg{status}, 'Unread', 'inbox status' );
        cmp_ok( $msg{message_id}, '>', 0, 'inbox messageID' );

        # Now read the message with read_message and check the fields again.
        my $mr = $myspace2->read_message( $msg{message_id} );

        is( $mr->{from}, $CONFIG->{acct1}->{friend_id}, "read_message From" );
        is( $mr->{subject}, 'Hi '.$ident, "read_message Subject" );
        #is( $mr->{date}, 'Feb 28, 2006 1:20 AM', "read_message Date" );
        is( $mr->{body}, "Just saying hi.\n\nHope all is well.", "read_message Body" );

        SKIP: {
            skip "delete_message tests disabled because Myspace's Delete button doesn't work", 2;

            # Now delete it
            ok( $myspace2->delete_message( \%msg ), "Delete Message" );

            # And make sure it's deleted
            my $message_id = $msg{message_id};
            $inbox = $myspace2->get_inbox( end_page => 2 );
            $found_message=0;
            foreach $msg ( @{$inbox} ) {
                if ( $msg->{message_id} == $message_id ) {
                    $found_message =1;
                    last;
                }
            }

            ok( ( ! $found_message ), 'Verified message deleted by delete_message' );
        }
    }
}

# Now test Message.pm
my $message = new WWW::Myspace::Message( $CONFIG->{'acct1'}->{'myspace'} );

$message->subject( "Hello" );

cmp_ok( $message->subject, "eq", 'Hello', "Message Subject" );

my $mymessage = 'This is a message from Message.\n\n- Me';

$message->body( $mymessage );

cmp_ok( $message->body, "eq", $mymessage, "Message Body" );

$message->friend_ids( $CONFIG->{'acct2'}->{'friend_id'} );
@friends = $message->friend_ids;

cmp_ok( $friends[0], "==", $CONFIG->{'acct2'}->{'friend_id'},
        "Friends to message" );

cmp_ok( $message->max_count, '==', 100, "max_count default is 100" );

$message->max_count( 49 );

cmp_ok( $message->max_count, '==', 49, "max_count set to 49" );

cmp_ok( $message->delay_time, '==', 86400,
        "delay_time default is 24 hours" );

# Lets try actually sending a message
$message->cache_file( "msgexcl" );

$message->add_to_friends( 1 );

$response = "";
$response = $message->send_message;

if ( ( $response eq "CAPTCHA" ) || 
     ( $response eq "COUNTER" ) ||
     ( $response eq "DONE" ) ) {
    $response = "P"
}

is( $response, 'P', 'Send message from Message' );
#diag('Response is ' . $response );

# Check the exclusions
@friends = $message->exclusions;
cmp_ok( $friends[0], '==', $CONFIG->{'acct2'}->{'friend_id'}, 
        'Exclusions list should have a friend' );
#diag( 'My friend is ' . $friends[0] );

cmp_ok( @friends, '==', 1, 'Exclusions list count should be 1' );

# Reset the exclusions
$message->reset_exclusions;

# Check the exclusions
@friends = $message->exclusions;
cmp_ok( @friends, '==', 0, 'Reset exclusions list' );

ok( ( ! -f $message->cache_file ), 'Exclusions list removed' );

# Test save/load
my $savefile="msave.yml";
#diag( "testing save/load in " . $savefile );
$message->save( $savefile );
$message->message( "none" );

ok( ( $message->message eq "none" ), "Save and clear message" );

$message->load( $savefile );
cmp_ok( $message->message, 'eq', "$mymessage", "Load message" );

# Clean up
unlink 'msave.yml';
