# $Id: Comment.pm 486 2007-09-22 20:05:58Z grantg $

package WWW::Myspace::Comment;

use Spiffy -Base;
use Carp;
use File::Spec::Functions;
use warnings;
use strict;

=head1 NAME

WWW::Myspace::Comment - Auto-comment your MySpace friends from Perl scripts

=head1 VERSION

Version 0.16

=cut

our $VERSION = '0.17';

=head1 WARNING

March 2007: Using WWW::Myspace for commenting, messaging, or adding
friends will probably get your Myspace account deleted or disabled.

=head1 SYNOPSIS

Simple module to leave a comment for each of our friends. 
This module is an extension of the Myspace module.

my $myspace = new WWW::Myspace;

my $comment = WWW::Myspace::Comment->new( $myspace );

my $result = $comment->post_comments( "Just stopping by to say hi!" );

Due to MySpace's security features, the post_comments method will, by
default, post 50 comments each time it's run. It logs the result of each
posting in a file so that it can be re-run daily without duplicating posts.
The file defaults to $myspace->cache_dir/commented. It
also checks each friend's profile page before posting to make sure we
haven't already left a comment there. This also prevents duplicates, but is
mostly designed to preserve posts (see note below).

See the documentation for the post_comments method below
for an example script to comment all friends using a loop.

Also see the comment_myspace script that is installed with the distribution.

=cut

#
######################################################################
# Setup

# How many should we post before stopping? (This is mostly
# to avoid CAPTCHA or overuse traps from tripping).
our $MAX_COUNT=50;

# Debugging?
our $DEBUG=0;

######################################################################
# Libraries we use

($DEBUG) && print "Getting Libraries...\n";

######################################################################
# new

=pod

=head1 METHODS

=head2 new( $myspace )

Initialze and return a new WWW::Myspace::Comment object.
$myspace is a WWW::Myspace object.

Example

use WWW::Myspace;
use WWW::Myspace::Comment;

my $myspace = new WWW::Myspace;

my $comment = WWW::Myspace::Comment->new( $myspace );

=cut

sub new() {
	my $proto = shift;
	my $class = ref($proto) || $proto;
 	my $self  = {};
	bless ($self, $class);
	if ( @_ ) {	$self->myspace( shift ) }
	unless ( $self->myspace ) {
		croak "No WWW::Myspace object passed to new method in WWW::Myspace::Comment.pm\n";
	}
	
	return $self;
}


#----------------------------------------------------------------------
# exclusions 

=head2 message

Retreives/sets the message we're going to leave as a comment.

=cut

field 'message';

=head2 friend_ids

Retreives/sets the list of friendIDs for whom we're going to
leave comments.

 $message->friend_ids( 12345, 12347, 123456 ); # Set the list of friends
 
 @friend_ids = $message->friend_ids; # Retreive the list of friends

=cut

sub friend_ids {
	if ( @_ ) {
		$self->{friend_ids} = \@_;
	} else {
		if ( defined ( $self->{friend_ids} ) ) {
			return @{ $self->{friend_ids} };
		} else {
			return ();
		}
	}
}

=head2 exclusions

Returns a list of the friends we're not going to comment (because
we already have). Returns the list in numerical order from lowest to
highest. You probably only need this method for communicating with
the user. Note that the post_comments method will also skip people
with a link to our profile (i.e. in a comment) on their page. The
exclusions list is 1) a safety that stops us from re-posting to
pages that need to approve comments, 2) prevents us from having to read
hundreds of profiles every time we run.

Example

( @exluded_friends ) = $comment->exclusions;

=cut

sub exclusions {
	
	return sort( keys( %{ $self->commented } ) );

}

=head2 commented

Returns a reference to a hash of friendIDs we've commented
and the status of the attempted commenting. Reads the data
from the exclusions cache file if it hasn't already been read.

=cut

sub commented {

	$self->_read_exclusions unless ( defined $self->{commented} );
	return $self->{commented};

}

=head2 cache_file

Sets or returns the cache filename. This defaults to "commented" in
the myspace object's cache_dir ($myspace->cache_dir/commented).

For convenience this method returns the value in all cases, so you
can do this:

$cache_file = $commented->cache_file( "/path/to/file" );

=cut

sub cache_file {

	if ( @_ ) {
		$self->{cache_file} = shift;
		return;
	} elsif (! defined $self->{cache_file} ) {
		# Make the cache directory if it doesn't exist
		$self->{myspace}->make_cache_dir;
		$self->{cache_file} = catfile( $self->{myspace}->cache_dir,
			'commented' );
	}

	return $self->{cache_file};

}

=head2 exclusions_file

This is a shortcut to "cache_file", which you should use instead.
exlucsions_file is here for backwards compatibility.

=cut

sub exclusions_file {

	return $self->cache_file(@_);

}


#----------------------------------------------------------------------
# max_count

=head2 max_count

Sets or returns the number of comments we should post before
stopping. Default: 50.

Call max_count( 0 ) to disable counting. This is good if you
can handle CAPTCHA responses and you want to stop only when you get
a CAPTCHA request (i.e. if you're running from a CGI
script that can pass them back to a user).

=cut

field max_count => $MAX_COUNT;

#----------------------------------------------------------------------
# html

=head2 html( [1] [0] )

Sets to display HTML-friendly output (only really useful with "noisy"
turned on also).

Call html(1) to display HTML tags (currently just "BR" tags).
Call html(0) to display plain text.

Text output (html = 0) is enabled by default.

Example

$comment->html( 1 );

=cut

field html => 0;

#----------------------------------------------------------------------
# delay_time

=head2 delay_time

Sets the number of seconds for which the post_all method will sleep
after reaching a COUNTER or CAPTCHA response. Defaults to 86400
(24 hours).

=cut

field delay_time => 86400;

#----------------------------------------------------------------------
# noisy

=head2 noisy( [1] [0] )

Retreives/Sets "noisy" output. That is, print status messages for each post.
If "html(1)" is called first, BR tags will be placed after each
line so you can display it as, say, the output of a CGI script.

If "noisy" is off, the post_comments method will run silently until
it hits a CAPTCHA response or until it hits its max_count.

set_noisy is off (0) by default.

=cut

field noisy => 0;

=head2 set_noisy

Shortcut for noisy, which you should use instead. set_noisy is here
for backwards compatibility.

=cut

sub set_noisy {

	$self->noisy( @_ );

}

=head2 interactive

If set to 1, and running on MacOS X, will pop up a CAPTCHA image in
Preview and prompt the user to enter it. (not yet implemented).

=cut

field interactive => 0;

=head2 myspace

Sets/retreives the myspace object with which we're logged in. You
probably don't need to use this as you'll pass it to the new method
instead.

=cut

field 'myspace';

#----------------------------------------------------------------------
# post_comments
# Post the comment to each friend, and keep a record of it.

=pod

=head2 post_comments( [ $message ], [ @friend_ids ] )

Posts comments to friends specified by @friend_ids. If none are given,
post_comments retrieves the list of all friends using the WWW::Myspace
object's get_friends method.

post_comments will automatically skip all friendIDs in the "exclusions"
list (see the exclusions method above). It will also scan each profile
page before posting, and if a link to our profile exists on the page,
it will not post. It will post until it has posted "max_count"
successful posts, or until it receives a CAPTCHA request ("please
enter the characters in the image above").

post_comments returns a status string indicating why it stopped:
CAPTCHA if a CAPTCHA image code was requested.
COUNTER if it posted max_count comments and stopped.
DONE if it posted everywhere it could.

Example

The following script will send the message "Hi!" to all of your
friends, and then reset the exlusions file.

 use WWW::Myspace;
 use WWW::Myspace::Comment;

 my $myspace = new WWW::Myspace;

 my $comment = WWW::Myspace::Comment->new( $myspace );
 my $response = "";
 
 # We're sending a message, doesn't matter if we've posted before
 $comment->ignore_duplicates(1);

 # Post our comment until we're done - may take several days if we're
 # popular.
 while ( 1 ) {
	$response = $comment->post_comments( "Hi!" );
	last if ( $response eq "DONE" );
	
	if ( $response eq "CAPTCHA" ) {
	
		#[ do nothing, or get the form, post it yourself, and continue ]
		#( Hint: the page is in $myspace->{current_page}->content )
	}

	# (If response is CAPTCHA or COUNTER, we wait then continue
	# until we're done). Note that you can probably sleep for 12 hours
	# instead of 24.
	sleep 24*60*60; #Sleep for a day, or run using cron
 }

 # We're done sending this message - reset the exclusions file
 # completely.
 $comment->reset_exclusions('all');

Note that because of the log post_comments keeps, this script could
be interrupted and restarted without re-posting anyone.

Example 2

This script will make sure you've always got a comment on your
friend's pages.

 use WWW::Myspace;
 use WWW::Myspace::Comment;

 my $myspace = new WWW::Myspace;

 my $comment = WWW::Myspace::Comment->new( $myspace );
 my $response = "";
 
 # Post our comment until we're done - may take several days if we're
 # popular.
 while ( 1 ) {
	$response = $comment->post_comments( "Hi!" );
	
	if ( $response eq "DONE" ) {
		# We're done sending this message - reset the exclusions 
		# file, except for people who approve their comment posts.
		# This causes us to start over, posting only if we don't
		# already have a comment on their page (i.e. if it's been
		# pushed off).
		$comment->reset_exclusions;
		last;
	}
		
	# (If response is CAPTCHA or COUNTER, we wait then continue
	# until we're done). Note that you can probably sleep for 12 hours
	# instead of 24.
	sleep 24*60*60; #Sleep for a day, or run using cron
 }

 # (Also see post_all below, which implements this loop).

=cut

sub post_comments {

	my ( $message, @friend_ids ) = @_;

	# If we got friends, set the friend_ids method, otherwise, get
	# our friend IDs from the method.
	if ( @friend_ids ) {
		$self->friend_ids( @friend_ids );
	} else {
		@friend_ids = $self->friend_ids;
	}

	# Do the same for the message
	if ( $message ) {
		$self->message( $message );
	} else {
		$message = $self->message;
	}

	# Initialize our convenience variables
	my $result = "";
	my $id = "";
	my $counter = 0;
	my $myspace = $self->myspace;

	return 0 unless ( $message );

	# If we weren't passed any friendIDs, get them from WWW::Myspace.	
	unless ( @friend_ids ) { @friend_ids = $myspace->get_friends }
	$self->friend_ids( @friend_ids );

	foreach $id ( @friend_ids ) {

		# If they're not on the exclude list, post a comment.
		unless ( $self->commented->{"$id"} ) {

				if ( $self->noisy ) { 
					if ( $self->html ) { print "<P>" }
					print "Posting to $id: ";
				}
				
				# See if we've already left a comment there
				if  ( 	( ! $self->ignore_duplicates ) &&
						( $myspace->already_commented( $id ) ) 
					) {
					$result = "PP"; # Posted Previously
				} else {
					$result = $myspace->post_comment( $id, $self->message );
					# Try a workaround if we got a CAPTCHA response
					if ( ( $result eq 'FC' ) &&
						( defined $self->{send_message_on_captcha} ) ) {
						$self->_send_message;
						$result = $myspace->post_comment( $id, $self->message );
					}

					$counter++ if ( $result =~ /^P/ );
				}
				# Log our attempt and the result
				$self->_write_exclusions( $id, $result );
				
				# Debugging code to help track down a weird occasional bug
				# that causes this module to die with:
				# Can't call WWW::Myspace::post_comment in boolean context 
				# at /Library/Perl/5.8.6/WWW/Myspace/Comment.pm line 448
#				if ( warn(  ref $result ) ) {
#					confess "Comment post result is a reference of type " . ref $result . "\n".
#						"result value: $result\n" .
#						"friendID: $id, message: " . $self->message
#				}
	
				# Notify the user and if necessary act on the result
				if ( $self->noisy ) {
					if ( $result =~ /^P/ ) {
						if ( $result eq "PA" ) {
							print "Succeeded, requires approval";
						} elsif ( $result eq "PP" ) {
							print "Skipped, previous comment or mention found on page";
						} else {
							print "Succeeded";
						}
						if ( $self->html ) { print "<br>" }
						print "\n";
					} else {
						print "Failed";
						if ( $result eq "FC" ) {
							print ", CAPTCHA response requested."
						} elsif ( $result eq "FL" ) {
							print ", Add Comment link not found on profile page."
						} elsif ( $result eq "FN" ) {
							print ", Network error."
						}
						if ( $self->html ) { print "<br>" }
						print "\n";
						( $DEBUG ) && print "\n\n" . $myspace->current_page->status_line .
							"\n" . $myspace->current_page->decoded_content . "\n\n";
					}
				}
				
				if ( $result eq "FC" ) {
					if ( $self->noisy ) {
						print "Stopping.";
						if ( $self->html ) { print "<br>" }
						print "\n";
					}
					
					return "CAPTCHA";
				}
		} else {
#			print "Excluding $id\n" if ( $self->noisy );
		}

		# If we've got a max set, stop when we reach it.		
		return "COUNTER" if ( ( $self->max_count ) && ( $counter >= $self->max_count ) );

	}

	return "DONE";	

}

=head2 post_all

This convenience method implements the while loop script example in the
post_comments section above. If the response is "DONE", it exits. Otherwise, it
sleeps for the number of seconds set in "delay_time" and calls post_comments
again. It repeats this until it receives "DONE" from the post_comments
method. post_all does NOT reset the exclusions file. If delay_time is 0, it
returns instead of sleeping.

Returns the response code it gets from post_comments, which will always
be "DONE" unless delay_time is set to 0, in which case it could be any
of the codes returned by post_comments.

EXAMPLE
 use WWW::Myspace;
 use WWW::Myspace::Comment;
 
 my $comment = new WWW::Myspace;
 my $comment = new WWW::Myspace::Comment( $myspace );

 # Send the message
 $comment->message("This is a great message wraught with meaning.");
 $comment->friend_ids( $myspace->get_friends );
 $comment->post_all;

 # Or

 # Send the message
 $comment->post_all( "This is a great message", $myspace->get_friends );

=cut

sub post_all {

	my $response = "";

	# Send our message to our friends until we're done - may take
	# several days if we're popular.
	while ( 1 ) {
		# Send to as many as we can right now. Will stop either
		# because it's DONE, it was asked for a CAPTCHA response,
		# or because it maxed out the COUNTER.
		$response = $self->post_comments( @_ );
		
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

sub _send_message {
	print "Sending message...\n";
	$self->myspace->send_message( 48449904, 'Hello', 'Just saying hi!', 0 );
}

sub _is_macos {

	eval { my $os = `/usr/bin/uname`; return ( $os eq "Darwin" ); }

}

=head2 ignore_duplicates( [ 1 | 0 ] )

By default post_comments will not post on a page if it detects
that a previous comment by the user as whom it's logged in has been
posted there.  If you call:

$comment->ignore_duplicates(1)

before calling post_comments, it will post without checking the
page for previous comments. It will still check the exclusions list
however.

Call $comment->ignore_duplicates(0) to return to checking for
comments before posting (this is the default).

Use this option if you're posting a new, specific comment
(like "Merry Christmas", "Check out my new album") and you
don't care if there's already another comment by you on people's
pages.

=cut

field ignore_duplicates => 0;

=head2 reset_exclusions

=head2 reset_exclusions( 'all' )

Resets the exclusions file, leaving only friends with "PA"
(posted, requires approval) status. If called with "all", resets
the entire file.

The reason for leaving friends with "PA" status is probably best
described with an example. Say you have 700 friends. You want to
hit each of their pages with "Just stopping by to say hi!".
So you set your comment script to run every day at 11am until
you get a return status of "DONE" (with 700 friends that'd take
14 days). After that you want to keep running the script, posting
only to pages that your comment has dropped off of. Conveniently,
post_comments will do that for you by default. So you call
reset_exclusions. If someone requires comments to be approved, your
comment might not appear on their page (yet). If you keep the script
running daily, resetting exlusions (because it'd hit "DONE" every day),
you'd spam that poor person every day. So, by default, reset_exclusions
will clear everything EXCEPT friends that approve comments.

If you want to override that behavior, call reset_exclusions( 'all' ).
You'd use this if, for example, you were sending a specific comment
to all of your friends (i.e. "Merry Christmas" or "Check out my new
album!"). It doesn't matter if you then send another comment.
In this case, you probably want to call ignore_duplicates(1) also.

=cut

sub reset_exclusions {

	my ( $all ) = @_;

	if ( ( defined $all ) && ( $all eq "all" ) ) {
		unlink $self->cache_file or croak @!;
		$self->{commented} = undef;
	} else {
		# Read only friends we've commented that approve posts.
		$self->_read_exclusions('PA');
		# Write that to the exclusions file.
		$self->_write_exclusions('all');
	}

}


#---------------------------------------------------------------------
# _write_exclusions
# If called with "all", write $self->{commented} to the exclusions
# file.
# If called with friendID and status, append a line to the exclusions
# file.

sub _write_exclusions
{
	my ( $friend_id, $status ) = @_;

	# We track who we've posted to in a file. We need to
	# open and close it each time to make sure everyone
	# gets stored.
	if ( $friend_id eq 'all' ) {
		# Re-write the file (called by reset_exclusions).
		open( COMMENTED, ">", $self->cache_file ) or croak @!;
		foreach $friend_id ( keys( %{ $self->{commented} } ) ) {
			$status = $self->{'commented'}->{"$friend_id"};
			print COMMENTED "$friend_id:$status\n";
		}
	} else {
		# Just append the current friend and status.
		open( COMMENTED, ">>", $self->cache_file ) or croak @!;
		print COMMENTED "$friend_id:$status\n";
		$self->{'commented'}->{"$friend_id"} = $status;
	}
	
	close COMMENTED;

}


#----------------------------------------------------------------------
# _read_exclusions( $options )
# Return the list of friendIDs we've already commented.
# Optional argument can be "PA", in which case we'll only set the list
# to those we have previously commented that require approval.
# This allows us to re-post if our comment has fallen off their page.

sub _read_exclusions {

	my $options = "";
	( $options ) = @_ if ( @_ );
	
	my %commented=();
	my $status = "";
	my $id;

	if ( -f $self->exclusions_file ) {
		open( COMMENTED, "<", $self->cache_file ) or croak 
			"Can't read cache file: " . $self->cache_file . "\n";
	} else {
		$self->{commented} = {};
		return;
	}
		
	while ( $id = <COMMENTED> ) {
		chomp $id;
		( $id, $status ) = split( ":", $id );
		
		# If they're logged as successfully posted or as invalid,
		# Add them to the exclusions list.
		if ( $status =~ /^P|^FI/i ) {
			$commented{"$id"} = $status unless
					( ( $options eq "PA" ) && ( $status ne "PA" ) );
		}
	}
	
	close COMMENTED;
	
	$self->{commented} = \%commented;

}

=pod

=head1 SEE ALSO

perldoc comment_myspace - The comment_myspace script is installed with the
WWW::Myspace distribution and uses this module.

=head1 AUTHOR

Grant Grueninger, C<< <grantg at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-myspace at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Myspace>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 KNOWN ISSUES

=head1 NOTES

CAPTCHA: WWW::Myspace allows 50 to 55 posts before requiring a CAPTCHA response,
then allows 3 before requiring it again. Not sure what the timeout
is on this, but running 50 a day seems to work.

Note that the main points of leaving comments are:

  - Keep ourselves in our fans memory,
  - Be "present" in as many places as possible.

We want to appear to "be everywhere". Since we
can only post to about 50 pages a day, we maximize our exposure by
checking each page we're going to post on to see if we're already there
and skipping it if we are.

=head1 TO DO

  - Provide a CGI interface so band members can
    coordinate and type in the CAPTCHA code. Interface
    would act as a relay: for each person we'd auto-post
    to, display the filled in comment form and have them
    customize it and/or fill in the captcha code. Could run
    in semi-automatic mode where it'd only display the page
    for them if it got a code request.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Myspace::Comment

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

Copyright 2005, 2006 Grant Grueninger, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of WWW::Myspace::Comment
