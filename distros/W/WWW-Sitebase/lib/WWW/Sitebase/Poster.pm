# $Id: Poster.pm,v 1.1 2013/12/22 05:33:16 grant Exp $

package WWW::Sitebase::Poster;

use warnings;
use strict;
use WWW::Sitebase -Base;
use IO::Prompt;
use Carp;
use File::Spec::Functions;
use List::Compare;

=head1 NAME

WWW::Sitebase::Poster - Base class for web site posting routines

=head1 VERSION

Version 0.4

=cut

our $VERSION = '0.4';

=head1 SYNOPSIS

 package MyPostingModule;
 
 use WWW::Sitebase::Poster -Base;
 
 # Define your options
 sub default_options {
    my $options = super;

    $options->{cache_file} = { default => 'mypostingmodule' }; # (VERY IMPORTANT)
    $options->{my_option} = 0;  # 0 = not required. 1 means required.
    $options->{my_option} = { default => 'mydefault' }; # Sets a default for your option.
    
    # Some common example options, say for posting messages or comments:
    $options->{subject} = 1;  # Require subject
    $options->{message} = 1;  # Require a message

    return $options;

 }
 
 # Add accessors if you like (usually a good idea)
 # (Poster.pm already gives you the cache_file accessor).
 field 'my_option';
 field 'subject';
 field 'message';
 
 # Define your send_post method (see examples below)
 sub send_post {
 
    my ( $friend_id ) = @_;

    $result = $self->browser->do_something( $friend_id, $other_value );

    # ... Do anything else you need ...
    
    return $result;  # $result must be P, R, F, or undef. (Pass, Retry, Fail, or stop)

 }
 
 
 ----------------
 Then you or others can write a script that uses your module.
 
 #!/usr/bin/perl -w
 
 use MyPostingModule;
 use WWW::Myspace;
 
 my @friend_list = &fancy_friend_gathering_routine;
 
 my $poster = new MyPostingModule(
    browser => new WWW::Myspace,  # Note, this'll prompt for username/password
    friend_ids => \@friend_list,
    subject => 'hi there!',
    message => 'I'm writing you a message!',
    noisy => 1,
    interactive => 1,
 );
 
 $poster->post;

This is a base class for modules that need to post things and remember
to whom they've posted.
If you're writing a new module that needs to send something and
remember stuff about it, you'll want to look at this module. It gives
you all sorts of neat tools, like write_log and read_log to remember
what you did, and it automatically parses all your arguments right
in the new method, and can even read them from a
config file in CFG or YAML format.  All the "new" method stuff it just
inherits from WWW::Sitebase, so look there for more info.

The cache_file is where write_log and read_log write and read their data.

You MUST set the cache_file default to something specific to your module.
This will be used by the cache_file method to return (and create if needed)
the default cache file for your module.  Make sure it's unique to "Poster" modules.
(Hint: name it after your module). Your default filename will be placed
in the value returned by $self->cache_dir (.www-poster by default), so don't
specify a path.  If you're writing a WWW::Myspace module, you
should override cache_dir.  See "cache_dir" below.

This module itself is a subclass of WWW::Sitebase, so it inherits
"new", default_options, and a few other methods from there. Be
sure to read up on WWW::Sitebase if you're not familiar with it,
as your class will magically inherit those methods too.

If you're writing a script that uses a subclass of this module,
you can read up on the methods it provides below.

=cut

=head1 OPTIONS

The following options can be passed to the new method, or set using
accessor methods (see below).

Note that if you're writing a script using a subclass of this module,
more options may be available to the specific subclass you're
using.

 Options with sample values:
 
 friend_ids => [ 12345, 123456 ],  # Arrayref of friendIDs.
 cache_file => '/path/to/file',
 max_count => 50,  # Maximum number of successful posts before stopping
 html => 1,        # 1=display in HTML, 0=plain text.
 delay_time => 86400,  # Number of seconds to sleep on COUNTER/CAPTCHA
 interactive => 1,  # Can we ask questions? Turns on noisy also.
 noisy => 1,  # Display detailed output (1) or be quiet (0)?
 browser => $myspace,  # A valid, logged-in site browsing object (i.e. WWW::Myspace,
                       # or a subclass of WWW::Sitebase::Navigator).

=cut

=head2 default_options

Override this method to allow additional options to be passed to
"new".  You should also provide accessor methods for them.
These are parsed by Params::Validate.  In breif, setting an
option to "0" means it's optional, "1" means it's required.
See Params::Validate for more info. It looks like this:

    sub default_options {
    
        $self->{default_options} = {
            friend_ids          => 0,
            cache_file          => 0,
            html                => 0,
            browser             => 0,
            exclude_my_friends  => { default => 0 },
            interactive         => { default => 1 },
            noisy               => { default => 1 },
            max_count           => { default => 0 },
        };
        
        return $self->{default_options};
    }

    # So to add a "questions" option that's mandatory:

    sub default_options {
        super;
        $self->{default_options}->{questions}=1;
        return $self->{default_options};
    }

=cut

sub default_options {

    $self->{default_options} = {
        friend_ids          => 0,
        cache_file          => 0,
        html                => 0,
        browser             => 0,
        exclude_my_friends  => { default => 0 },
        interactive         => { default => 1 },
        noisy               => { default => 1 },
        max_count           => { default => 0 },
    };
    
    return $self->{default_options};
}


=head2 friend_ids

Retreives/sets the list of friendIDs for whom we're going to
post things.

 $message->friend_ids( 12345, 12347, 123456 ); # Set the list of friends
 
 @friend_ids = $message->friend_ids; # Retreive the list of friends

You can set the friend_ids to a list of friends, an arrayref to a list
of friends, or to an object whose "get_friends" method will return
the list of friends.

When called without arguments, returns a list of friends (even if you
set it with an arrayref). 

=cut

sub friend_ids {
    if ( @_ ) {
        if ( ref $_[0] ) {
            $self->{friend_ids} = $_[0];
        } else {
            $self->{friend_ids} = \@_;
        }
    } else {
        # If $self->{friend_ids} is set, it's either an array ref
        # to a list of friends, or an object that we need to call
        # "get_friends" on, which will return a list of friends.
        if ( defined ( $self->{friend_ids} ) ) {
            if ( ref $self->{friend_ids} eq "ARRAY" ) {
                return @{ $self->{friend_ids} };
            } else {
                return $self->{friend_ids}->get_friends;
            }
        } else {
            return ();
        }
    }
}

=head2 cache_dir

cache_dir sets or returns the directory in which we should store cache
data. Defaults to $ENV{'HOME'}/.www-poster.

If you're subclassing this module to write a module that will use
WWW::Myspace, you should override this method with something like:

 sub cache_dir { $self->browser->cache_dir( @_ ) }

This will put your module's cache data neatly into the same place as the
other WWW::Myspace modules' data.

=cut

# Get and scrub the path to their home directory.
our $HOME_DIR= "";
if ( defined $ENV{'HOME'} ) {
    $HOME_DIR = "$ENV{'HOME'}";
    
    if ( $HOME_DIR =~ /^([\-A-Za-z0-9_ \/\.@\+\\:]*)$/ ) {
        $HOME_DIR = $1;
    } else {
        croak "Invalid characters in $ENV{HOME}.";
    }
}

field cache_dir => catfile( "$HOME_DIR", '.www-poster' );

=head2 cache_file

Sets or returns the cache filename. This defaults to
$self->default_options->{cache_file}->{default} in cache_dir.
If you try to call cache_file without a value and you haven't set
default_options properly, it'll get really pissed off and throw nasty
error messages all over your screen.

For convenience this method returns the value in all cases, so you
can do this:

$cache_file = $commented->cache_file( "filename" );

=cut

sub cache_file {

    if ( @_ ) {
        $self->{cache_file} = shift;
    } elsif (! defined $self->{cache_file} ) {
        # Make the cache directory if it doesn't exist
        $self->make_cache_dir;
        $self->{cache_file} =  $self->default_options->{cache_file}->{default};
    }

    return $self->{cache_file};

}

=head2 cache_path

Returns the full path to the cache_file.

=cut

sub cache_path {

    # Make the cache directory if it doesn't exist.
    $self->make_cache_dir;

    return catfile( $self->cache_dir, $self->cache_file );
}

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

=head2 browser

Sets/retreives the site navigation object with which we're logged in.
You'll probably just pass that info to the new method, but the accessor is here
if you want to use it.

 Hint: To make your module more site-specific, add a convenience method:
 
 sub myspace { $self->browser( @_ ) }
 
 or
 
 sub bebo { $self->browser( @_ ) }

=cut

field 'browser';

=head2 exclude_my_friends

Sets/retrieves the value of the "exclude_my_friends" flag.
If set to a true value, the "post" method will exclude the logged-in
user's friends from the list of friendIDs set in the "friend_ids" method.

This works by calling the "get_friends" method of the browser object.  If
the object stored in "browser" doesn't have a "get_friends" method, the
"post" routine will die.

Note that getting friends can take some time, so it's best to have your
friend list properly filtered instead of using this option.  But, it's here
if you need it.

=cut

field 'exclude_my_friends';

=head2 interactive

If set to 1, allows methods to ask questions by displaying a prompt and
reading STDIN.  Setting to 0 makes the script run non-interactively.
Setting to 1 automatically sets "noisy" to 1 also.

=cut

sub interactive {

    if ( @_ ) {
        ( $self->{interactive} ) = @_;
        if ( $self->{interactive} ) { $self->noisy(1) }
    }
    
    return $self->{interactive};
    
}

=head2 noisy( [1] [0] )

If set to 1, the module should output status reports for each post.
This, of course, will vary by module, and you'll probably want to
document any module-specific output in your module.

If "noisy" is off (0), run silently, unless there is an error, until
you have to stop. Then you may print a report or status.

noisy is off (0) by default.

=cut

field noisy => 0;

=head2 max_count

Sets or returns the number of posts we should attempt before
stopping.  Default: 0 (don't stop).

This is handy if you want to stop before a CAPTCHA response, or if you
want to limit your daily posts.  Override this to set a default that's
appropriate for your module (i.e. 50 for a Myspace commenting module)

=cut

field max_count => 0;

=head1 POSTING

=head2 send_post

You must override this method with your posting method. It will be
called by the "post" method and passed an ID from the list of friend_ids
(set using the option to the "new" method or using the "friend_ids" accessor method).
It must return two values: a result code (P, R, F, or undef) and a human-readable
reason string.  The result codes mean "Pass", "Retry", "Fail", and "stop!" respectively,
and the human-readable reason will be used in the report output when the "post"
method stops.

 Example:
 # Send Myspace group invitations.  The send_group_invitation method returns two
 # array references, one of passed IDs and one of failed.  We want to retry any
 # failures.
 sub send_post {
     my ( $id ) = @_;
     
     my ( $passed, $failed ) = $self->browser->send_group_invitation( $id );
     
     # We only passed 1 ID, so if "passed" has anything in it, our ID passed.
     if ( @{ $passed } ) {
         return 'P', 'Invitation Sent';
     } else {
         return 'R', 'Invitation send failed';
     }
 }
 
 # Post a comment on Myspace.  There are several possible codes post_comment could
 # return, so we want to decide for each whether to retry or not. Also, if we reach a
 # CAPTCHA response, we want to stop. Note that this example assumes your
 # subclass module defined "subject" and "message" accessors.
 sub send_post {
     my ( $id ) = @_;
    
     my $result = $self->browser->post_comment( $id, $self->subject, $self->message );
    
     if ( $result eq 'P' ) {
         return 'P', 'Passed';
     } elsif ( $result eq 'FC' ) {
         return undef;
     } elsif ( $result eq 'FN' ) {
         return 'R', "Network error";
     } elsif ( $result eq 'FF' ) { 
         return 'F', 'Person is not your friend';
     } else {
         return 'R', 'Failed - reason unknown';
     }
 }

=cut

stub 'send_post';

=head2 post

This is the main method of the module.  It is called to do the actual
posting.  It gathers the friendIDs and loops through them, calling the
"send_post" method to send each post.  It handles logging each post,
and excluding previously-posted friends.

=cut

sub post {

    no strict 'refs';

    # Check for browser object
    croak "Must set a valid browser object before calling post method"
         unless ( $self->browser );

    $self->{post_count} = 0;
    my ( $result, $reason );
    my ( @friend_list ) = $self->friend_ids;

    ( @friend_list ) = $self->_exclude_friends( @friend_list );
    
    unless ( @friend_list ) { $self->_report( "Nothing to process\n" ); return; }

    foreach my $id ( @friend_list ) {
        ( $result, $reason ) = $self->send_post( $id );
        last unless ( $result );

        $self->_record_result( $id, $result, $reason );
        $self->{post_count}++ unless ( $result eq 'R' );

        last if ( $self->max_count && ( $self->{post_count} > $self->max_count ) );
    }

    $self->_final_report;

}

=head2 post_count

Returns the current number of successful posts (from the internal
counter used by the "post" method.

 # Pause after every 25th post
 sleep 30 if ( ( $self->post_count % 25 ) == 0 );

=cut

sub post_count { $self->{post_count} }

sub _record_result {
    my ( $friend_id, $result, $reason ) = @_;
    
    unless ( $result =~ /^[PFR]$/o ) {
        croak "Invalid result code: \"$result\".\n".
              "Valid codes are P, R, or F (Pass, Retry, or Fail).";
    }

    $self->write_log( { friend_id => $friend_id, status => $result } );
    $self->{reasons}->{$reason}++;

}

sub _final_report {

    no strict 'refs';

    print "\n\nFinal status report...\n\n######################\n";

    foreach my $reason ( keys( %{ $self->{reasons} } ) ) {
        print $self->{reasons}->{$reason} . " " . $reason;
    }
    
    print "\n";

}

sub _exclude_friends {
    my ( @friend_list ) = @_;
   
    my @exclude_list = ();
    
    # Exclude our friends if they asked.
    if ( $self->{'exclude_my_friends'} ) {
        $self->_report("Getting friend IDs to exclude. This could take a while.\n");
        push @exclude_list, $self->browser->get_friends;
    }
    
    # Exclude previous posts
    $self->_report( "Retreiving list of previous posts\n" );
    push @exclude_list, $self->read_posted('all');

    # Process the exclusions
    $self->_report( "Processing exclusions...\n" );
    my $lc = List::Compare->new(
        {
            lists => [ \@exclude_list, \@friend_list],
            accelerated => 1, # Only one comparison
            unsorted => 1,    # Unsorted
        }
    );

    return ( $lc->get_complement );

}

=head1 LOGGING METHODS

=head2 reset_log( [ $filter ] )

Resets the log file.  If passed a subroutine reference in $filter,
items matching filter will be left in the log - everything else will
be erased.

Say for example you wanted to retry all "Failed" items:

 $filter = sub { ( $_->{'status'} eq "P" ) };
 $self->reset_log( $filter );

To delete the log file completely, just do:

 $self->reset_log;

=cut

sub reset_log {

    my ( $filter ) = @_;

    unless ( defined $filter ) {
        unlink $self->cache_path or croak @!;
        $self->{log} = undef;
    } else {
        # Read in the items to save
        $self->read_log( $filter );

        # Write that to the exclusions file.
        $self->write_log('all');
    }

}


#---------------------------------------------------------------------

=head2 write_log( 'all' | $data )

If called with "all", write $self->{log} to the log file.
If called with a hash of data, append a line to the log
file.

 $self->write_log( 'all' );
 
 $self->write_log( {
    friend_id => $friend_id,
    status => $status
 } );
 
If there is a "time" field in the list of log_fields (there is by default),
write_log will automatically write the current time (the value returned by
the "time" function) to the file.

=cut

sub write_log
{
    no strict 'refs';
    my ( $data ) = @_;

    my ( $fh, $key_field, $key_value );
    # We track who we've posted to in a file. We need to
    # open and close it each time to make sure everyone
    # gets stored.
    if ( $data eq 'all' ) {
        # Re-write the file (called by reset_exclusions).
        # ($fh closes when it goes out of scope)
        open( $fh, ">", $self->cache_path ) or croak @!;
        foreach $key_value ( sort( keys( %{ $self->{log} } ) ) ) {
            $self->$print_row( $key_value, $fh );
        }
    } else {
        # Just append the current data.
        # ($fh closes when it goes out of scope)
        open( $fh, ">>", $self->cache_path ) or croak @!;
        
        # Write the data into the log hash
        $key_field = $self->log_fields->[0]; # i.e. "friend_id"
        $key_value = $data->{"$key_field"}; # i.e. "12345"
        
        # Add the time if it's not there
        unless ( exists $data->{'time'} ) {
            $data->{'time'} = time;
        }
        # Store the rest of the passed data into the log hash.
        $self->{'log'}->{$key_value} = $data;
        
        # Write that row to the log file.
        $self->$print_row( $key_value, $fh );
    }

}

# print_row( $row_key, $fh );
# Print the row of data from the log hash specified by $row_key to the
# file identified by the filehandle reference $fh.

my sub print_row {

    no strict 'refs';
    my ( $row_key, $fh ) = @_;
    
    # Assemble the row
    my $row = "";
    foreach my $fieldname ( @{ $self->log_fields } ) {
        ( $row ) && ( $row .= ":" );
        $row .= $self->{log}->{$row_key}->{"$fieldname"};
    }

    # Print to the file
    print $fh "$row\n";


}

=head2 log_fields

Returns a reference to an array of the columnn names you use in your
log file. Defaults to friend_id, status, and time. The first field
will be used as your unique key field.

Override this method if you want to use different columns in your
log file.

=cut

const 'log_fields' => [ 'friend_id', 'status', 'time' ];



#----------------------------------------------------------------------

=head2 read_log

Read items from the log file. The first time it's invoked, it
reads the log file contents into $self->{log}, which is also
neatly maintained by write_log. This lets you call read_log
without worrying about huge performance losses, and also
makes it extendable to use SQL in the future.

For future compatibility, you should access the log only through
read_log (i.e. don't access $self->{log} directly).

 # Post something unless we've successfully posted before
 unless ( $self->read_log("$friend_id")->{'status'} =~ /^P/ ) {
    $myspace->post_something( $friend_id )
 }

 # When did we last post to $friend_id?
 $last_time = $self->read_log("$friend_id")->{'time'};
 
 if ( $last_time ) {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
        localtime($last_time);
    print "Successfully posted to $friend_id on: " .
        "$mon/$day/$year at $hour:$min:sec\n";;
 } else {
    print "I don't remember posting to $friend_id before\n";
 }

read_log can be called with an optional filter argument, which can
be the string "all", or a reference to a subroutine that will
be used to filter the returned values.  The subroutine will be
passed a hashref of fieldnames and values, by default:

 { friend_id => 12345,
   status => P,
   time => time in 'time' format
 }

This lets you do things like this:

 # Reload the cache in memory ($self->{log})
 $self->read_log( 'all' )

 # Return a list of friends that we've already posted
 # ("the 'o' flag means to optimize the RE because the RE is a constant).
 my $filter = sub { if ( $_->{'status'} =~ /^[PF]$/o ) { 1 } else { 0 } }
 @posted_friends = $self->read_log( $filter );
 
 # Of course, that's just for example - you'd really do this:
 @posted_friends = $self->read_log( sub { ( $_[0]->{'status'} =~ /^[PF]$/o ) } );

 # or this, which means "return anything that doesn't need to be retried"
 # (this is, in fact, what "read_posted" (see below) does).
 @posted_friends = $self->read_log( sub { ( $_[0]->{'status'} ne 'R' ) } );

Only the last post attempt for each key (friend_id by default) is stored
in $self->{log}.  It is possible for the cache file to have more than one
in some circumstances, but only the last will be used, and if the file
is re-written, previous entries will be erased.

=cut

sub read_log {

    no strict 'refs';
    my $filter = "";
    ( $filter ) = @_ if ( @_ );
    
    my $status = "";
    my $id;
    my @values;

    # If we haven't read the log file yet, do it.
    unless ( ( defined $self->{log} ) && ( $filter ne 'all' ) ) {
        
        if ( -f $self->cache_path ) {
            open( LOGGED, "<", $self->cache_path ) or croak 
                "Can't read cache file: " . $self->cache_path . "\n";
        } else {
            $self->{log} = {};
            return $self->{log};
        }

        # There's a cache file, so read it
        while ( $id = <LOGGED> ) {
            chomp $id;
            ( @values ) = split( ":", $id );
    
            # Match the values to the appropriate fieldnames
            my $i = 0;
            my %data = ();
            foreach my $value ( @values ) {
                my $fieldname = $self->log_fields->["$i"];
                $data{"$fieldname"}=$value;
                $i++;
            }
            
            $self->{'log'}->{"$values[0]"} = { %data };
    
        }
        
        close LOGGED;
        
    }

    # If we reloaded, we're done.
    return $self->{log} if ( $filter eq 'all' );
    
    # If they passed a specific key value instead of a filter subroutine,
    # return the appropriate record if it exists.
    if ( ( $filter ) && ( ! ref $filter ) ) {
        if ( exists $self->{log}->{"$filter"} ) {
            return $self->{log}->{$filter}
        } else {
            return "";
        }
    }
    
    # Unless we've got a real filter, return.
    unless ( ref $filter ) {
        return $self->{log};
    }
    
    # Return a list of keys that matches their filter
    my @keys = ();
    foreach my $key_value ( sort( keys( %{ $self->{log} } ) ) ) {
        if ( &$filter( $self->{log}->{"$key_value"} ) ) {
            push( @keys, $key_value );
        }
    }

    return ( @keys );

}

=head2 read_posted

Returns the keys of all posted rows (status isn't "R").

my @posted_friends = $self->read_posted;

=cut

sub read_posted {

    return ( $self->read_log( sub { ( $_[0]->{'status'} ne 'R' ) } ) );
 
}

=head2 previously_posted( $friend_id )

This convenience method returns true if there's a log entry for
a previous successful posting. A posting is considered successful
if the status code is "P" or "F".

 unless ( $self->previously_posted( $friend_id ) ) {
    $self->post( $friend_id );
 }

=cut

sub previously_posted {

    return ( $self->read_log( $_[0] )->{'status'} ne 'R' );

}

sub _report {

    print @_ if $self->{'interactive'};

}

=head2 make_cache_dir

Creates the cache directory in cache_dir. Only creates the
top-level directory, croaks if it can't create it.

    $myspace->cache_dir("/path/to/dir");
    $myspace->make_cache_dir;

This function mainly exists for the internal login method to use,
and for related sub-modules that store their cache files by
default in WWW:Myspace's cache directory.

=cut

sub make_cache_dir {

    # Make the cache directory if it doesn't exist.
    unless ( -d $self->cache_dir ) {
        mkdir $self->cache_dir or croak "Can't create cache directory ".
            $self->cache_dir;
    }

}

# This tells Sitebase we don't want to save the browser field.
sub _nosave {
    my ( $key ) = shift;

    if ( $key && ( $key eq 'browser' ) ) { return 0 }
    return 1;

}

=pod

=head1 AUTHOR

Grant Grueninger, C<< <grantg at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-myspace at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Sitebase-Poster>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Sitebase::Poster

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Sitebase-Poster>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Sitebase-Poster>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Sitebase-Poster>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Sitebase-Poster>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Grant Grueninger, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of WWW::Sitebase::Poster
