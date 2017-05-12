# $Id: Message.pm 486 2007-09-22 20:05:58Z grantg $

package WWW::Myspace::Message;

use Spiffy -Base;
use Carp;
use File::Spec::Functions;
use YAML;
use warnings;
use strict;

=head1 NAME

WWW::Myspace::Message - Auto-message your MySpace friends from Perl scripts

=head1 VERSION

Version 0.16

=cut

our $VERSION = '0.17';

=head1 WARNING

March 2007: Using WWW::Myspace for commenting, messaging, or adding
friends will probably get your Myspace account deleted or disabled.

=head1 SYNOPSIS

 use WWW::Myspace;
 use WWW::Myspace::Message;
 
 my $myspace = new WWW::Myspace;
 
 my $message = new WWW::Myspace::Message( $myspace );
 
 $message->subject("Hi there!");
 $message->message("I'm sending you a message!\nIsn't that cool?\n");
 $message->add_to_friends( 1 );
 $message->friend_ids( $myspace->get_friends );
 $message->send_message;

The above will send a message to all our myspace friends, stopping
if it sends max_count messages or if it receives a CAPTCHA request.
Running the same routine again will continue sending where it left
off, so if you have a lot of friends you could run it from a cron job.

WWW::Myspace::Message lets you create a message and send it to a group of
friends.
It implements a counter to avoid tripping WWW::Myspace anti-spam features.
If you want to circumvent anti-spam features, this is not the module for you.

EXAMPLES

Since you may have more than 300 people to message, the following script
will send a message to all of your friends, and then reset the exclusions file.
This allows it to run as a sort of daemon. It will run for days
if necessary and stop when finished.

 use WWW::Myspace;
 use WWW::Myspace::Message;

 my $myspace = new WWW::Myspace;

 my $message = WWW::Myspace::Message->new( $myspace );
 $message->subject("Hi there!");
 $message->message("I'm sending you a message!\nIsn't that cool?\n");
 $message->friend_ids( $myspace->get_friends );

 my $response = "";

 # Send our message to our friends until we're done - may take
 # several days if we're popular.
 while ( $response ne "DONE" ) {
	# Send to as many as we can right now. Will stop either
	# because it's DONE, it was asked for a CAPTCHA response,
	# or because it maxed out the COUNTER.
	$response = $message->send_message;

	# Wait for a day. (You can probably wait for just 12 hours).
	sleep 24*60*60;
 }

 # We're done sending this message - reset the exclusions file
 # completely.
 $message->reset_exclusions;

Note that because of the log WWW::Myspace::Message keeps, either script could
be interrupted and restarted without re-sending to anyone.

The "while" loop above can be replaced with the "send_all" convenience
method:

 $message->send_all;

This is probably the most practical example:

 # Set up
 use WWW::Myspace;
 use WWW::Myspace::Message;

 my $myspace = new WWW::Myspace;

 # Create the message
 my $message = WWW::Myspace::Message->new( $myspace );
 $message->subject("Hi there!");
 $message->message("I'm sending you a message!\nIsn't that cool?\n");
 $message->friend_ids( $myspace->get_friends );

 # Send our message to our friends until we're done - may take
 # several days if we're popular.
 $message->send_all;

 # We're done sending this message - reset the exclusions file
 # completely.
 $message->reset_exclusions;

Again, you could kill and restart this script and it'd pick up where
it left off (and even incorporiate any changes in your friend list!).
Of course if it finished and you restarted it, it'd re-message everyone.

=cut

#
######################################################################
# Setup

# IF YOU ADD A FIELD, ADD IT TO THIS LIST. Otherwise it will not be
# loaded or saved.

our @PERSISTENT_FIELDS = (
	'subject', 'message', 'friend_ids', 'cache_file', 'max_count',
	'noisy', 'html', 'delay_time', 'add_to_friends', 'message_delay',
	'random_delay', 'skip_re'
	);

=head1 ACCESSOR METHODS

=head2 myspace

Sets/retreives the myspace object through which we'll send the message.

=cut

field 'myspace';

=head2 subject

Sets/retreives the subject of the message we're to post.

=cut

field 'subject';

=head2 message

Sets/retrieves the message we're to post.

=cut

field 'message';

=head2 body

Convenience method, same as calling "message".
($message->body("this is my message") reads better sometimes).

=cut

sub body {
	$self->message( @_ )
}

=head2 add_to_friends

 $message->add_to_friends( 1 );

If called with 1 true value, HTML code for an "Add to friends"
button will be added to the end of the message.

IMPORTANT NOTE: As of August, 2006 Myspace turns this code into a
"view profile" code, which currently redirects until the browser locks up or
reports an error.  So, setting this to 1 will now display a
"View My Profile" link at the end of the message instead of an
"Add to friends" button.

=cut

field add_to_friends => '0';

=head2 skip_re

 $message->skip_re( 'i hate everybody!* ?(<br>)?' );

If set, is passed to the send_message method in Myspace.pm causing
profiles that match the RE to be skipped.  This failure is logged
so the profile will not be attempted again, to prevent a huge list
of failed profiles from forming and being retried over and over if
you're running the script daily.

=cut

field 'skip_re';

=head2 friend_ids

Sets/retreives the list of friend IDs to which we're going to send
the message.

 $message->friend_ids( 12345, 12347, 123456 ); # Set the list of friends
 
 @friend_ids = $message->friend_ids; # Retreive the list of friends

=cut

sub friend_ids {
	if ( @_ ) {
		$self->{friend_ids} = [ @_ ];
	} else {
		return @{ $self->{friend_ids} };
	}
}

=head2 cache_file

WWW::Myspace::Message keeps persistent track of which friends it's
messaged to avoid duplicates even across multiple runs. It saves
data about its messaging in the file specified in cache_file.
Defaults to $myspace->cache_dir/messaged. cache_file will be created if it
doesn't exist. If you specify a path, all directories in the path
must exist (the module will not create directories for you).

=cut

sub cache_file {

	if ( @_ ) {
		$self->{cache_file} = shift;
		return;
	} elsif (! defined $self->{cache_file} ) {
		# Make the cache directory if it doesn't exist
		$self->{myspace}->make_cache_dir;
		$self->{cache_file} = catfile( $self->{myspace}->cache_dir,
			'messaged' );
	}

	return $self->{cache_file};

}

=head2 max_count

Defaults to 100. This sets how many messages we'll post before pausing.
This is mostly to avoid triggering overuse messages. (You're allowed
about 360 per day (possibly per 12 hours period?)).

=cut

field max_count => 100;

=head2 noisy

Defaults to 0 (not noisy). If set to 1, detailed progress will
be output.

=cut

field noisy => 0;

=head2 html

Defaults to 0. If set to 1, the "noisy" output will contain basic
HTML tags so you can send the output to a web browser. Use this if
you're displaying using a CGI script.

=cut

field html => 0;

=head2 delay_time

Defaults to 24 hours (24*60*60). Specifies the amount of time to
wait between sends when using the send_all method. If set to 0,
send_all will return instead of sleeping. This is useful if you
want to run a script daily from a crontab for example.

=cut

field delay_time => 24*60*60;

=head2 message_delay

Sets the delay between message sends.  Defaults to 0, but you
probably want to set this to something like 10.

=cut

field message_delay => 0;

=head2 random_delay

If set to 1, delays randomly between 3 seconds and the value of
message_delay + 3. Defaults to 0.

=cut

field random_delay => 0;

=head2 paired_arguments

This method is used internally to define the -s and -m flags.
If you subclass WWW::Myspace::Message, you can override this
method to define more switches. The values of these are loaded
into $self->{arguments}. i.e. $self->{arguments}->{'-s'} would
give you the subject of the message.

=cut

#sub boolean_arguments { qw(-has_spots -is_yummy) }
sub paired_arguments { qw(-s -m ) }

# Debugging?
our $DEBUG=0;

######################################################################
# Libraries we use

($DEBUG) && print "Getting Libraries...\n";

######################################################################
# new

=head1 METHODS

=head2 new( $myspace )

Initialze and return a new WWW::Myspace::Message object.
$myspace is a WWW::Myspace object.

Example

use WWW::Myspace;
use WWW::Myspace::Message;

my $myspace = new WWW::Myspace;

my $message = new WWW::Myspace::Message( $myspace );

=cut

sub new() {
	my $proto = shift;
	my $class = ref($proto) || $proto;
 	my $self  = {};
	bless ($self, $class);
	if ( @_ ) {	$self->{myspace} = shift }
	unless ( $self->{myspace} ) {
		die "No WWW::Myspace object passed to new method in WWW::Myspace::Message.pm\n";
	}

	# Parse any arguments they passed.
	my @friends = ();
	if ( @_ ) {
		( $self->{arguments}, @friends ) = $self->parse_arguments( @_ );
		foreach my $arg ( '-s', '-m' ) {
			$self->{ { '-s' => 'subject',
						'-m' => 'message'
					  }->{"$arg"} } = $self->{arguments}->{ "${arg}" };
		}
		$self->friend_ids( @friends );
	}

	return $self;
}


#----------------------------------------------------------------------
# exclusions 

=pod

=head2 exclusions

Returns a list of the friends we're not going to send the message to
(because we already have). Returns the list in numerical order from lowest
to highest. You probably only need this method for communicating with
the user.

Example

( @already_messaged ) = $message->exclusions;

=cut

sub exclusions {
	
#	$self->_read_exclusions unless ( defined $self->{messaged} );
	return sort( keys( %{ $self->messaged } ) );

}

=head2 messaged

Returns a reference to a hash of friendIDs we've messaged
and the status of the attempted messaging. Reads the data
from the exclusions cache file if it hasn't already been read.

=cut

sub messaged {

	$self->_read_exclusions unless ( defined $self->{messaged} );
	return $self->{messaged};

}

#----------------------------------------------------------------------
# send_message
# Send the message to each friend, and keep a record of it.

=head2 send_message

Send the message to the friends in the friend_ids list.

The send_message method will automatically skip all friendIDs in
the "exclusions" list (see the exclusions method above).
It will post until it has posted "max_count"
successful posts, or until it receives a CAPTCHA request ("please
enter the characters in the image above").

As of version 0.14, send_message will check the Last Login date
of the friend_id to which it's sending each message (using Myspace.pm's
"last_login" method).  If the Last Login is older than 60 days ago,
the friendID will be skipped and "FL" will be logged.  The friendID
will be exluded from future runs to prevent future runs from re-checking
a huge list of probably dead accounts.

send_message returns a status string indicating why it stopped:

 CAPTCHA if a CAPTCHA image code was requested.
 USAGE if we got a message saying we've exceeded our daily usage.
 COUNTER if it posted max_count comments and stopped.
 FAILURES if it keeps getting errors (more than 50 in a row).
 DONE if it posted everywhere it could.

=cut

sub send_message {

	my $result = "";
	my $id;
	my $counter = 0;
	my $myspace = $self->{myspace};
	my $subject = $self->subject;
	my $message = $self->message;
	my @friend_ids = $self->friend_ids;
	my $failures = 0;
	$self->_read_exclusions unless ( defined $self->{messaged} );

	return "DONE" unless ( ( $message ) && ( @friend_ids ) );

	foreach $id ( @friend_ids ) {
	
		# If they're not on the exclude list, send the message.
		unless ( $self->messaged->{"$id"} ) {

				if ( $self->html ) { print "<P>" }
				if ( $self->noisy ) { print $counter+1 . ": Sending to $id: " };
				# Check for dead accounts
				if ( ( $myspace->last_login( $id ) &&
					   ( $myspace->last_login > time - 60*86400 )
					 )
				   ) {
				    $result = $myspace->send_message(
				    	friend_id => $id,
				    	subject => $subject,
				    	message => $message,
				    	atf => $self->add_to_friends,
				    	skip_re => $self->skip_re
				    );
				} else {
					$result = "FL";
				}
				$counter++ if ( $result =~ /^P/ );

				# Log our attempt and the result
				$self->_write_exclusions( $id, $result );
	
				# Notify the user and if necessary act on the result
				if ( $self->noisy ) {
					if ( $result =~ /^P/ ) {
						print "Succeeded";
						if ( $self->html ) { print "<br>" }
						print "\n";
						$failures=0;
					} else {
						print "Failed";
						$failures++ if ( $result =~ /^FN?$/ );
						if ( $result eq "FC" ) {
							print ", CAPTCHA response requested."
						} elsif ( $result eq "FN" ) {
							print ", Network error."
						} elsif ( $result eq "FF" ) {
							print ", Profile set to private."
						} elsif ( $result eq "FA" ) {
							print ", User is away."
						} elsif ( $result eq "FL" ) {
							print ", inactive account. User hasn't ".
								  "logged in in 60 days."
						}
						if ( $self->html ) { print "<br>" }
						print "\n";
						( $DEBUG ) && print "\n\n" . $myspace->current_page->status_line .
							"\n" . $myspace->current_page->decoded_content . "\n\n";
					}
				}
				
				if ( ( $result eq "FC" ) || ( $result eq "FE" ) ) {
					if ( $self->noisy ) {
						print "Stopping.";
						if ( $self->html ) { print "<br>" }
						print "\n";
					}
					
					return "CAPTCHA" if ( $result eq "FC" );
					return "USAGE" if ( $result eq "FE" );
				}
				
				# If we fail more than 50 times in a row, stop.
				if ( $failures > 50 ) {
					print "Too many consecutive failures, stopping.\n";
					return "FAILURES";
				}
		} else {
#			if ( $self->noisy ) { print "Excluding $id\n" }
		}

		# If we've got a max set, stop when we reach it.		
		return "COUNTER" if ( ( $self->max_count ) &&
							  ( $counter >= $self->max_count )
							);

		# Delay if we're supposed to
		$self->_delay;
	}

	return "DONE";	

}

=head2 send_all

This convenience method implements the while loop script example in the
SYNOPSIS section above. If the response is "DONE", it exits. Otherwise, it
sleeps for the number of seconds set in "delay_time" and calls send again.
It repeats this until it receives "DONE" from the send method.
send_all does NOT reset the exclusions file.

Returns the last response code received from send_message.  This will
always be "DONE" unless delay_time is set to 0 (which is redundant,
but exists for scripting convenience as it allows users of your
script to set delay_time to 0 if they want to control the messaging,
without you having to call a different method - see message_group for
example).

EXAMPLE
 use WWW::Myspace;
 use WWW::Myspace::Message;
 
 my $myspace = new WWW::Myspace;
 my $message = new WWW::Myspace::Message( $myspace );

 $message->subject("Hi there!");
 $message->message("This is a great message wraught with meaning.");
 $message->friend_ids( $myspace->get_friends );
 $message->send_all;

=cut

sub send_all {

	my $response = "";

	# Send our message to our friends until we're done - may take
	# several days if we're popular.
	while ( 1 ) {
		# Send to as many as we can right now. Will stop either
		# because it's DONE, it was asked for a CAPTCHA response,
		# or because it maxed out the COUNTER.
		$response = $self->send_message;
		
		last if ( $response eq "DONE" );
	
		# Wait
		if ( $self->noisy ) {
			print "Got " . $response . "\n";
			print "Sleeping " . $self->delay_time . " seconds...";
			print "<br>" if ( $self->html );
			print "\n";
		}

		# Sleep only if delay_time > 0, otherwise we're done.
		last unless ( $self->delay_time > 0 );

		sleep $self->delay_time;
	}
	
	return $response;

}

=head2 reset_exclusions

Resets the cache file (which contains previously messaged friendIDs
that we'd exclude).

=cut

sub reset_exclusions {

	unlink $self->cache_file or croak $!;
	$self->{messaged} = undef;
	
#	my ( $all ) = @_;
#
#	if ( $all eq "all" ) {
#		unlink "$MESSAGED_LIST" or croak @!;
#	} else {
#		# Read only friends we've messaged that approve posts.
#		$self->_read_exclusions('PA');
#		# Write that to the exclusions file.
#		$self->_write_exclusions('all');
#	}

}


#---------------------------------------------------------------------
# _write_exclusions
# If called with "all", write $self->{messaged} to the $MESSAGED_LIST
# file.
# If called with friendID and status, append a line to the $MESSAGED_LIST
# file.

sub _write_exclusions {

	my ( $friend_id, $status ) = @_;

	# We track who we've posted to in a file. We need to
	# open and close it each time to make sure everyone
	# gets stored.
	if ( $friend_id eq 'all' ) {
		# Re-write the file (called by reset_exclusions).
		open( MESSAGED, ">", $self->cache_file ) or croak 
			"Can't write cache file: " . $self->cache_file;
		foreach $friend_id ( keys( %{ $self->{messaged} } ) ) {
			$status = $self->{'messaged'}->{"$friend_id"};
			print MESSAGED "$friend_id:$status\n";
		}
	} else {
		# Just append the current friend and status.
		open( MESSAGED, '>>', $self->cache_file ) or croak
			"Can't write cache file: " . $self->cache_file;
		print MESSAGED "$friend_id:$status\n";
		$self->{'messaged'}->{"$friend_id"} = $status;
	}
	
	close MESSAGED;

}


#----------------------------------------------------------------------
# _read_exclusions( $options )
# Return the list of friendIDs we've already messaged.
# Optional argument can be "PA", in which case we'll only set the list
# to those we have previously messaged that require approval.
# This allows us to re-post if our comment has fallen off their page.

sub _read_exclusions {
	
	my %messaged=();
	my $status = "";
	my $id;

	if ( -f $self->cache_file ) {
		open( MESSAGED, "<", $self->cache_file ) or croak 
			"Can't read exclusions file: ". $self->cache_file . "\n";
	} else {
		$self->{messaged} = {};
		return;
	}
		
	while ( $id = <MESSAGED> ) {
		chomp $id;
		( $id, $status ) = split( ":", $id );
		
		# If they're logged as successfully posted, private, away,
		# invalid, or unused, add them to the exclusions list.
		if ( $status =~ /^P|^FF|^FA|^FI|^FL/i ) {
			$messaged{"$id"} = $status
		}
	}
	
	close MESSAGED;
	
	$self->{messaged} = \%messaged;

}

=head2 save( filename )

Saves the message to the file specified by "filename".

=cut

sub save {

	my $data = {};

	# For each field listed as persistent, store it in the
	# hash of data that's going to be saved.
	foreach my $key ( @PERSISTENT_FIELDS ) {
		# IMPORTANT: Only save what's defined or we'll
		# break defaults.
		if ( exists $self->{$key} ) {
			${$data}{$key} = $self->{$key}
		}
	}
	
	# Save the data. We use eval to delay loading these modules
	# as load and save aren't frequently used.
	open ( STOREFILE, ">", $_[0] ) or croak $!;
	print STOREFILE Dump( $data );
	close STOREFILE;
	
}

=head2 load( filename )

Loads a message in YAML format (i.e. as saved by the save method)
from the file specified by filename.

=cut

sub load {

	my ( $file ) = @_;
	my $data = {};
	my $x = "";
	my $line;

	# Load the data. We use eval to delay loading these modules
	# as load and save aren't frequently used.
	open( STOREFILE, "<", $file ) or croak $!;
	foreach $line ( <STOREFILE> ) {	$x .= $line }
	close STOREFILE;
	
	( $data ) = Load( $x );

	# For security we only loop through fields we know are
	# persistent. If there's a stored value for that field, we
	# load it in.
	foreach my $key ( @PERSISTENT_FIELDS ) {
		if ( exists ${$data}{$key} ) {
			$self->{$key} = ${$data}{$key}
		}
	}
	
}

# _delay
# Sleep according to the values set in $self->message_delay and
# $self->random_delay.

sub _delay {

	my $delay_time = 0;
	if ( $self->random_delay ) {
		$delay_time = int( rand( $self->message_delay + 3 ) );
	} else {
		$delay_time = $self->message_delay;
	}
	
	sleep $delay_time;
}

=head1 AUTHOR

Grant Grueninger, C<< <grantg at cpan.org> >>

=head1 BUGS

=over

=item *

new method should probably accept a hash of arguments to set
all accessable settings (i.e. cache_file). Should also be
callable with no arguments.

=item *

If cache_file is called with no arguments and cache_file has not been
set, it will create the cache dir by invoking the make_cache_dir
method of the myspace object. It should probably not create the
directory until it's actually writing to the file. Of course,
if you don't set cache_file, the first time the method is called
would be when writing to the cache file.

=item *

If the myspace object hasn't been passed to the WWW::Myspace::Message
object yet, and cache_file is called to retreive the default cache_file,
the method will croak (as it's trying to call $myspace->make_cache_dir).

=item *

If you somehow write to the exclusions file before the exclusions
file has been read, $self->messaged will not read the exclusions
cache file, and will therefore have an incomplete list. This
shouldn't happen in normal operation as the send_message method
reads the exclusions file when it's called.

=back

Please report any bugs or feature requests to
C<bug-www-myspace at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Myspace>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Myspace::Message

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Myspace>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Myspace>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Myspace>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Myspace>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Grant Grueninger, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
