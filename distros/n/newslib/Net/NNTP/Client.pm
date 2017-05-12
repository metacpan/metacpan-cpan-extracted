$VERSION = 0.6;
package Net::NNTP::Client;
our $VERSION = '0.6';

# -*- Perl -*-
###############################################################################
# Written by Tim Skirvin <tskirvin@killfile.org>
# Relies extensively on code from Net::NNTP, which was written and maintained 
# by Graham Barr <gbarr@pobox.com>.  Thanks.
# 
# Copyright 2000, Tim Skirvin.  Redistribution terms are below.
###############################################################################

=head1 NAME

Net::NNTP::Client - a module to simulate an entire NNTP client

=head1 SYNOPSIS

  use Net::NNTP::Client;
  my $client = new Net::NNTP::Client('news.cso.uiuc.edu',
	'server' => 'news.cso.uiuc.edu',  'port' => 119,
	'user'   => 'guest',		  'pass' => 'guest' );

See below for the list of functions.

=head1 DESCRIPTION

Net::NNTP is a module designed to provide a common interface to NNTP
servers.  This module is an extension of this; it contains a Net::NNTP
reference, in addition to various cached information about the server and
enough information to reconnect again in the case of a hang-up.  

=cut


use strict;		# Good programming is our friend
use Net::NNTP;		

use vars qw( $DEBUG $TIMEOUT );
$DEBUG    = 1;
$TIMEOUT  = 120;

=head1 METHODS

=over 4

=item new ( NAME [, OPTIONS] ) 

Creates a new object and returns it.  C<NAME> is mandatory, and is the
name of the connection, as well as (by default) the server name. C<OPTIONS> 
is a list of key/value pairs; the useful keys are:

name, server, port, user, pass, debug, timeout

Each of these can be modified with its corresponding function.

=item name ( [NAME] )

Returns the name of the object.  If C<NAME> is passed, then it sets the
name to its value.  

=item server ( [SERVER] )

Returns the NNTP server name that the object will connect to.  If
C<SERVER> is passed, then it sets the server name to its value.

=item port ( [PORT] )

Returns the TCP port number that the object will communicate with.  If
C<PORT> is passed, then the port number is set to its value.

=item user ( [USER] )

Returns the user name that the object will authenticate itself to the NNTP
server with.  If C<USER> is passed, then the user name is set to its value.

=item pass ( [PASS] )

Returns the password that the object will authenticate itself to the NNTP
server with.  If C<PASS> is passed, then the password is set to its value.

=item debug ( [DEBUG] )

Returns true if we should print debugging information from the NNTP 
connection.  Can be set with C<DEBUG>.  

=item timeout ( [TIMEOUT] )

Returns the timeout value of the NNTP connection.  Defaults to 120.
Can be set with C<TIMEOUT>.

=cut

sub new {
  my ($class, $name, %hash) = @_;
  return undef unless $name;
  my $object = {
    'NAME' 	=> $name,
    'SERVER'    => $hash{'server'}   || $name,
    'PORT'	=> $hash{'port'}     || 119,
    'USER'	=> $hash{'user'}     || "",
    'PASS'  	=> $hash{'pass'}     || "",
    'DEBUG'     => $hash{'debug'}    || $DEBUG,
    'TIMEOUT'   => $hash{'timeout'}  || $TIMEOUT,
    'NNTP'      => undef,
  };
  bless $object, $class;
  $object;
}

sub name { my ($self, $arg) = @_; $arg ? $$self{NAME} = $arg : $$self{NAME}; }
sub server { 
  my ($self, $arg) = @_; 
  $arg ? $$self{SERVER} = $arg 
       : $$self{SERVER} ;
}
sub port { my ($self, $arg) = @_; $arg ? $$self{PORT} = $arg : $$self{PORT} }
sub user { my ($self, $arg) = @_; $arg ? $$self{USER} = $arg : $$self{USER} } 
sub pass { my ($self, $arg) = @_; $arg ? $$self{PASS} = $arg : $$self{PASS} }
sub timeout { 
  my ($self, $arg) = @_; $arg ? $$self{TIMEOUT} = $arg : $$self{TIMEOUT};
}
sub debug { 
  my ($self, $arg) = @_; defined $arg ? $$self{DEBUG} = $arg 
				      : $$self{DEBUG} ;
}

=item connect ()

=item reconnect ()

=item nntp ()

These three functions create the socket connection to an NNTP server.
The connection is made to the server found by C<server()> and the port 
at C<port()>.  If the connection is already open, then it returns that
connection; otherwise, it reconnects and continues.  Either way, if
C<user()> and C<pass()> are set, then it authenticates as well.

=cut

sub nntp      { shift->connect(@_) }
sub reconnect { shift->connect(@_) }
sub connect {
  my $self = shift;
  my $connection = $$self{'NNTP'};  
  # If we're already connected, return the connection.  If we *look* 
  # like we're connected but aren't really, then close whatever it is
  # that looks like it was connected and continue.
  if ($connection) {	
    return $connection if $self->connected;	
    warn "Reconnecting to $$self{SERVER}\n" if $self->debug;
    $connection->quit;	
  }
  
  # (Re)connect to the server.  
  my $server = $self->server || return undef;  
  warn "Connecting to $server\n" if $self->debug;
  my $NNTP = Net::NNTP2->new( $server, 'debug' => $self->debug, 
				       'Port' => $self->port,
				       'timeout' => $self->timeout )
	|| warn "Couldn't connect to $server: $!\n";

  # Authorize ourselves if possible 
  my $user = $self->user || "";  my $pass = $self->pass || "";
  $NNTP->authinfo($user, $pass) if ($user && $pass);

  # Add to reconnect gracefully - NOT YET IMPLEMENTED
  # $NNTP->group($$self{GROUP}) if ($$self{GROUP});
  # $NNTP->nntpstat($$self{POINTER}) if ($$self{POINTER});

  # Set the local NNTP variable, and return the server connection
  $$self{'NNTP'} = $NNTP;
  $NNTP;
}

=item disconnect ()

Disconnect from the NNTP server.  

=cut

sub disconnect { $_[0]->{NNTP}->quit }

=item connected () 

If the object is currently connected to the NNTP server, returns 1;
otherwise, returns 0.

=cut

sub connected () {
  my $NNTP = shift->{'NNTP'} || return 0;
  $NNTP->date;		# Make sure we can still talk to it
  defined(fileno($NNTP)) ? 1 : 0;
}

=item load ( ITEM [, ARGS]  )

Loads C<ITEM> from the NNTP server, which is one of C<active>,
C<active.times>, C<newsgroups>, or C<overview.fmt>.  C<ARGS> is the list
of arguments to be passed into the appropriate NNTP call (see the
Net::NNTP manual pages for C<active()>, C<active_times()>, C<newsgroups()>,
and C<overview_fmt()> for details).  These items are cached; if no
arguments are passed in C<ARGS>, then this value will be returned instead
of fetching new information from the server.

=cut

sub load {
  my ($self, $item, $arg1, @args) = @_;
  warn "Loading $item from $$self{SERVER}\n" if $self->debug;
  my $NNTP = $self->nntp || return undef;
  
  if (lc $item eq '' || lc $item eq 'active') {
    return $$self{'ACTIVE'} if (!$arg1 && $$self{'ACTIVE'});
    my $active = $NNTP->active($arg1) || return undef; 
    $$self{ACTIVE} = $active;
    return $active;
  } elsif (lc $item eq 'active.times') {
    return $$self{'ACTIVE_TIMES'} if (!$arg1 && $$self{'ACTIVE_TIMES'});
    my $active_times = $NNTP->active_times() || return undef; 
    $$self{ACTIVE_TIMES} = $active_times;
    return $active_times;
  } elsif (lc $item eq 'newsgroups') {
    return $$self{'NEWSGROUPS'} if (!$arg1 && $$self{'NEWSGROUPS'});
    my $newsgroups = $NNTP->newsgroups($arg1) || return undef; 
    $$self{NEWSGROUPS} = $newsgroups;
    return $newsgroups;
  } elsif (lc $item eq 'overview.fmt') {
    return $$self{'OVERVIEW_FMT'} if (!$arg1 && $$self{'OVERVIEW_FMT'});
    my $overviewfmt = $NNTP->overview_fmt() || return undef; 
    $$self{'OVERVIEW_FMT'} = $overviewfmt;
    return $overviewfmt;
  } else {
    return undef;
  }
}

=item Net::NNTP Methods

The following methods from Net::NNTP are directly implemented by this object.  
The real difference is that they will all try to reconnect to the server
before running themselves; if this fail, then they return undef. Refer to 
L<Net::NNTP> for details on how to use them.

article, head, body, nntpstat, group, ihave, last, date, postok, authinfo,
newgroups, newnews, next, post, slave, quit, distributions, subscriptions,
xgtitle, xhdr, xover, xpath, xpat, xrover, listgroup

Also, these functions have been re-implemented with C<load()>.

active, active_times, newsgroups, overview_fmt, list 

And C<quit()> has been re-implemented with C<disconnect()>.

=cut

# * = should keep track of $POINTER and $GROUP with these

sub article   { my $nntp = shift->nntp || return undef;  $nntp->article(@_) } #*
sub head      { my $nntp = shift->nntp || return undef;  $nntp->head(@_) }
sub body      { my $nntp = shift->nntp || return undef;  $nntp->body(@_) }
sub last      { my $nntp = shift->nntp || return undef;  $nntp->last(@_) }    #*
sub nntpstat  { my $nntp = shift->nntp || return undef;  $nntp->nntpstat(@_) }#*
sub group     { my $nntp = shift->nntp || return undef;  $nntp->group(@_) }   #*
sub ihave     { my $nntp = shift->nntp || return undef;  $nntp->ihave(@_) }
sub date      { my $nntp = shift->nntp || return undef;  $nntp->date(@_) }
sub postok    { my $nntp = shift->nntp || return undef;  $nntp->postok(@_) }
sub authinfo  { my $nntp = shift->nntp || return undef;  $nntp->authinfo(@_) }
sub newgroups { my $nntp = shift->nntp || return undef;  $nntp->newgroups(@_) }
sub newnews   { my $nntp = shift->nntp || return undef;  $nntp->newnews(@_) }
sub next      { my $nntp = shift->nntp || return undef;  $nntp->next(@_) }    #*
sub post      { 
  warn "Posting: @_\n";
  my $nntp = shift->nntp || return undef;  
  $nntp->post(@_) 
}
sub slave     { my $nntp = shift->nntp || return undef;  $nntp->slave(@_) }
sub distributions { 	# Didn't quite fit in 80 columns.
  my $nntp = shift->nntp || return undef; 
  $nntp->distributions(@_) 
}
sub subscriptions { 	# Again, didn't quite fit in 80 columns.
  my $nntp = shift->nntp || return undef; $
  nntp->subscriptions(@_) 
}
sub xgtitle   { my $nntp = shift->nntp || return undef;  $nntp->xgtitle(@_) }
sub xhdr      { my $nntp = shift->nntp || return undef;  $nntp->xhdr(@_) }
sub xover     { my $nntp = shift->nntp || return undef;  $nntp->xover(@_) }
sub xpath     { my $nntp = shift->nntp || return undef;  $nntp->xpath(@_) }
sub xpat      { my $nntp = shift->nntp || return undef;  $nntp->xpat(@_) }
sub xrover    { my $nntp = shift->nntp || return undef;  $nntp->xrover(@_) }
sub listgroup { my $nntp = shift->nntp || return undef;  $nntp->listgroup(@_) }

sub active       { shift->load('active', @_) }
sub active_times { shift->load('active.times', @_) }
sub list         { shift->load(shift || 'active', @_) }
sub newsgroups   { shift->load('newsgroups', @_) }
sub overview_fmt { shift->load('overview_fmt', @_) }
sub quit         { shift->disconnect(@_) }

# Added to give better error messages
sub code      { my $nntp = shift->nntp || return undef;  $nntp->code(@_) }
sub message   { my $nntp = shift->nntp || return undef;  $nntp->message(@_) }

=head1 REQUIREMENTS

Requires C<Net::NNTP>.

=head1 NOTES

If you hadn't noticed, the real point of this is that this can be used
in the place of Net::NNTP in a lot of situations.  It doesn't offer too
many advantages above it, though.  Oh well.  

=head1 SEE ALSO

L<Net::NNTP::Proxy>, L<newsproxy.pl>, L<Net::NNTP>, L<News::NNTPAuth>

=head1 TODO

The caching done by C<load()> isn't all that hot.  I'm not sure of its
robustness for reconnections yet.  

=head1 AUTHOR

Written by Tim Skirvin <tskirvin@killfile.org>.

=head1 COPYRIGHT

Copyright 2000 by Tim Skirvin <tskirvin@killfile.org>.  This code may be
redistributed under the same terms as Perl itself.

=cut

### Net::NNTP2
# This is pretty much just Net::NNTP, with a few changes made to make it 
# compatible with Net::NNTP::Client.  Nobody should know of this thing
# unless you're reading over the code directly.  

package Net::NNTP2;

use strict;
use Net::NNTP;

use vars qw(@ISA);
@ISA = qw( Net::NNTP );

# Get rid of the DESTROY function, because the default one is broken if
# multiple processes have the filehandle open (which we want to have
# happen.)  This declaration causes a warning if we aren't making a new
# class, which is why we *are* making one.
sub DESTROY {} 		

1;

###############################################################################
### Version History ###########################################################
###############################################################################
# v0.5a 	Thu Nov  9 17:25:24 CST 2000
### First version ready for release.  Generally does its job.  The caching
### work isn't the best, and I'm not sure about the robustness of the 
### reconnect()/isconnected() code.  
# v0.6		Thu Apr 22 11:43:07 CDT 2004 
### No real changes, just internal layout changes.
