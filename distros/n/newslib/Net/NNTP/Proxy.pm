$VERSION = '0.54';
package Net::NNTP::Proxy;
our $VERSION = '0.54';

# -*- Perl -*-
###############################################################################
# Written by Tim Skirvin <tskirvin@killfile.org>
# Relies extensively on code from Net::NNTP, which was written and maintained 
# by Graham Barr <gbarr@pobox.com>.  Thanks.
#
# Copyright 2000-2002, Tim Skirvin.  Redistribution terms are below.
###############################################################################


=head1 NAME

Net::NNTP::Proxy - a news server in perl

=head1 SYNOPSIS

  use Net::NNTP::Proxy;
  my $server = new Net::NNTP::Proxy || die "Couldn't start the server: $!\n"; 
  $server->push(new Net::NNTP::Client);
  $server->listen(9119);
  my $client = $server->connect;

See below for more functions.

=head1 DESCRIPTION

This package is a basic news server written in perl.  It contains a list
of Net::NNTP::Client connections, and talks to all of these to get its
data; it then serves it back out to a port just like a regular news server.  
It's also clean enough to run multiple-processes (and maybe even 
multi-threaded, if I'm lucky.)

newsproxy.pl is used to actually run this thing.

=head1 METHODS

=over 4

=cut

use strict;
use Socket;
use Errno qw(EAGAIN);
use News::Article;

use vars qw($DEBUG $MAXCONN $CONNMESSAGE $PORT $NEWLINE);

### Variables #################################################################
$DEBUG = 1;		# Should debugging be on?  1 = yes, 0 = no.
$MAXCONN = 5;		# Maximum number of connections in the queue.
$CONNMESSAGE = "";	# Message to send when connected.
###############################################################################

$PORT = 119;		# Default news port
$NEWLINE = "\r\n";	# Newline string

=head2 NETWORK AND FUNCTIONALITY 

These functions create the object and connect it to the network.

=item new ( )

Create a new server object.  Doesn't actually bind to the port; you still
need to use C<listen()> for that.

=cut

sub new {
  my $class = shift; 
  my $object = {};  
  bless $object, $class;
  $object->_init('port', shift);
}

### _init ( KEY, VALUE [...] )
# Do the work for new().  And clone(), if I decide to make one.
sub _init {
  my ($self, %hash) = @_;

  # User-modified variables
  $$self{'NEWSSERVERS'}	  = $hash{'newsservers'} || [];

  # Cached variables
  $$self{'SERVER'}        = $hash{'server'}    || "";
  $$self{'GROUP'}         = $hash{'group'}     || "";
  $$self{'POINTER'}       = $hash{'pointer'}   || 0;
  $$self{'ARTICLES'}      = $hash{'articles'}  || [];

  # Internal variables
  $$self{'SOCKET'}        = $hash{'socket'}    || {};

  $self;
}

=item openport ( [PORT] )

Listens on C<PORT> for a TCP connection. 

=cut

sub openport {
  my ($self, $port) = @_;
  my $server = $self->_open_socket($port || 119);
  $$self{'SOCKET'} = $server if $server;;
  return $server ? $self : undef;
}

=item closeport ()

Stops listening for a TCP connection.

=cut

sub closeport {
  my ($self, @rest) = @_;
  $$self{'SOCKET'} ? close $$self{'SOCKET'}
		   : 0;
}

=item connect ( FILEHANDLE )

Connects to the given C<FILEHANDLE>.  Returns the filehandle again.

=cut

sub connect {
  my ($self, $fh) = @_;
  my $server = $$self{'SOCKET'} || return undef;
  $fh ||= \*CLIENT;
  accept($fh, $server);
  $fh;
}

=item disconnect ( FILEHANDLE )

Disconnects from C<FILEHANDLE>, closing it in the process.

=cut

sub disconnect {
  my ($self, $fh) = @_;  return undef unless $fh;
  return undef unless defined fileno($fh);
  close $fh;
}

=item process ( FILEHANDLE, LINE )

Process C<LINE>, which was received from C<FILEHANDLE>, and call the
appropriate news function (which are all documented below).  Returns 

=cut

sub process {
  my ($self, $fh, $line) = @_;   $line ||= $_;
  $line =~ s/^\s+|\s+$//g;		# Trim leading/trailing whitespace
  my ($command, @rest) = split('\s+', $line);
  my @return;
  if (lc $command eq 'authinfo') {
    @return = "400 Not yet implemented";
    # @return = $self->authinfo(@rest);
  } elsif (lc $command eq 'article') {		# Works
    # @return = $self->article($rest[0]);
    @return = $self->article($rest[0], 1, 1);
  } elsif (lc $command eq 'body') {		# Works - sortof
    @return = $self->article($rest[0], 0, 1);
    # @return = $self->body(@rest);
  } elsif (lc $command eq 'date') {		# Works
    @return = $self->date;
  } elsif (lc $command eq 'group') {		# Works
    @return = $self->group($rest[0]);
  } elsif (lc $command eq 'head') {		# Works - sortof
    @return = $self->article($rest[0], 1, 0);
    # @return = $self->head(@rest);
  } elsif (lc $command eq 'help') {		
    @return = "400 Not yet implemented";
    # @return = $self->help(@rest);
  } elsif (lc $command eq 'ihave') {
    @return = "400 Not yet implemented";
    # @return = $self->ihave(@rest);
  } elsif (lc $command eq 'last') {		# Works
    @return = $self->last();
  } elsif (lc $command eq 'list') {
    @return = $self->list(@rest);
  } elsif (lc $command eq 'listgroup') {	# Works
    @return = $self->listgroup($rest[0]);	
  } elsif (lc $command eq 'mode') {		# Works
    @return = $self->mode(@rest);
  } elsif (lc $command eq 'newgroups') {
    @return = "400 Not yet implemented";
    # @return = $self->newgroups(@rest);
  } elsif (lc $command eq 'newnews') {
    @return = "400 Not yet implemented";
    # @return = $self->newnews(@rest);
  } elsif (lc $command eq 'next') {		# Works
    @return = $self->next();
  } elsif (lc $command eq 'post') {		# Works mostly
    @return = $self->post($fh);
  } elsif (lc $command eq 'slave') {
    @return = "400 Not yet implemented";
    # @return = $self->slave(@rest);
  } elsif (lc $command eq 'stat') {		# Works
    @return = $self->stat($rest[0]);
  } elsif (lc $command eq 'xgtitle') {
    @return = "400 Not yet implemented";
    # @return = $self->xgtitle(@rest);
  } elsif (lc $command eq 'xhdr') {
    # @return = $self->xhdr(@rest);
  } elsif (lc $command eq 'xover') {		# Works, I think
    @return = $self->xover(@rest);
  } elsif (lc $command eq 'xpat') {
    @return = "400 Not yet implemented";
    # @return = $self->xpat(@rest);
  } elsif (lc $command eq 'xpath') {
    @return = "400 Not yet implemented";
    # @return = $self->xpath(@rest);
  } elsif (lc $command eq 'quit') {		# Works
    $self->quit($fh);
    return undef;
  } else {					# Works
    @return = $self->badcommand;
  }
  print $fh join ($NEWLINE, @return, '');
  1;
}

=head2 NEWS SERVERS 

These functions return and manipulate the list of news servers that the
object connects to and works with.

=item newsservers ( ) 

Returns a reference to an array containing the list of news servers that
can be accessed.  

=item push ( SERVER [, SERVER [, SERVER [...]]] )

Adds C<SERVER> item onto the end of the list of news servers.  

=item pop  ( ) 

Removes the first item from the list of the news servers.

=cut

sub newsservers { shift->{'NEWSSERVERS'} }
sub push { CORE::push ( @{shift->{'NEWSSERVERS'}}, @_ ) }
sub pop { unshift @{shift->{'NEWSSERVERS'}} }


=head2 NEWS FUNCTIONS 

These functions implement news functionality.  Return values are designed
to be written to a socket, which is taken care of by C<process()>.  None
of this stuff is overly well documented; it follows the NNTP standards
well where possible, however.

=item authinfo ( USER, PASS )

Not yet implemented.

=cut

sub authinfo { }

=item article ( ID [, HEAD, BODY] )

Retrieve and return the article indicated by C<ID>.  Looks through the
list of news servers in order; the first server to have the article
returns it.  

=cut

sub article { 
  my ($self, $id, $head, $body) = @_;  $id ||= "";
  return undef unless ($head || $body);
  my $article = $self->_article($id);	# Helper function
  if ($article && ref $article) {	# We got the article.
    my $ID = ($id =~ /^\d+$/) ? $id : 0;
    my $messageid = $article->header('message-id');
    my $code;  
    my @return;  
    if ($head) { 
      CORE::push @return, $body ? "220 $ID $messageid article"
	    		        : "221 $ID $messageid head"
    } else {
      CORE::push @return, "222 $ID $messageid body" if $body;
    }

    # We need to reformat the lines from rawheaders, which may include
    # newlines, for later reformatting
    if ($head) {
      my @headers = $article->rawheaders;
      foreach (@headers) { CORE::push @return, split("\n", $_); }
      CORE::push @return, "" if $body;	
    }

    # Fix a bug in Net::NNTP 
    if ($body) { map { s/^\./../o } @{$article->body} }
    CORE::push @return, $article->body if $body;
    CORE::push @return, ".";
    wantarray ? @return : join($NEWLINE, @return);
  } elsif ($article) {	# Error message - return it
    $article;
  } else {
    "420 No such article\n";
  }
}

=item body ( ID )

As C<article()>, but just returns the body.

=cut

sub body { shift->article($_[0], 0, 1) }

=item date ()

Returns the current date from the server.

=cut

sub date { 
  my @localtime = gmtime;
  sprintf("111 %04d%02d%02d%02d%02d%02d\n",
        $localtime[5] + 1900, $localtime[4] + 1, $localtime[3] + 1,
        $localtime[2], $localtime[1], $localtime[0]);
}

=item group ( GROUP )

Changes to the given C<GROUP>.

=cut

sub group { 
  my ($self, $group) = @_;  return undef unless $group;
  my ($newsgroup, $server) = $self->_group($group);
  return $self->nosuchgroup($newsgroup) unless ($newsgroup && $server);
  $$self{GROUP} = $newsgroup;  $$self{SERVER} = $server;
  my @list = $self->_listgroup($newsgroup, $server); my $count = scalar @list;
  sprintf('211 %d %d %d %s', $count || 0, $list[0] || 0, 
			$count ? $list[$count - 1] : 0, $group);
}

=item head ( ID ) 

As C<article()>, but just returns the headers.

=cut

sub head { shift->article($_[0], 1, 0) }

=item help ()

Not yet implemented.

=cut

sub help () { }

=item ihave ()

Not yet implemented

=cut

sub ihave { }

=item last ()

Stats the previous message, if there is one.  See C<stat()>.

=cut

sub last { 
  my $self = shift;
  if ($$self{POINTER} < 0) {
    "422 No Previous Article";
  } elsif ($$self{POINTER} == 0) {
    $$self{POINTER}--; "422 No Previous Article";
  } else {
    $$self{POINTER}--; $self->stat();
  }
}

=item list ( TYPE ARGS )

Lists off a certain value.  Valid values are:

  active ( PATTERN )
  active.times
  newsgroups ( PATTERN )
  overview.fmt (NOT YET IMPLEMENTED)

=cut

sub list { 
  my ($self, $type, @args) = @_;
  if (lc $type eq 'active' || lc $type eq '') {
    $self->_list_active(@args);
  } elsif (lc $type eq 'active.times' || $type eq 'active_times') {
    $self->_list_active_times(@args);
  } elsif (lc $type eq 'overview.fmt') {	# Tricky
  } elsif (lc $type eq 'newsgroups') {
    $self->_list_newsgroups(@args);
  } else {		# None of the supported lists -> bad command
    $self->badcommand;
  }
}

=item listgroup ( GROUP ) 

Loads up a given group, and gets a list of articles in it.  

=cut

sub listgroup { 	# Works!
  my ($self, $group) = @_;
  my ($newsgroup, $server) = $self->_group($group);
  return $self->nosuchgroup($group) unless ($newsgroup && $server);
  $$self{GROUP} = $newsgroup;  $$self{SERVER} = $server;
  my @list = $self->_listgroup($group, $server);   my $count = scalar @list;  
  return join("\n", "211 Article list follows", @list, ".");
}

=item mode ( STRING ) 

Sets the reader mode.  At present, only 'reader' works.

=cut

sub mode { 	# Works!  
  my ($self, $mode) = @_;
  return $self->badcommand unless lc $mode eq 'reader';
  return "200 " . ($CONNMESSAGE || "Welcome to $0");
}

=item newgroups ( GROUPS, DATE, TIME, [TZ] )

Not yet implemented

=cut

sub newgroups { } 

# newnews newsgroups yyyymmdd hhmmss [GMT]

=item newnews ( GROUPS, DATE, TIME, [TZ] )

Not yet implemented

=cut

sub newnews { }
# next
sub next { 
  my $self = shift;
  return $self->nogroupselect() unless (defined $$self{GROUP});
  if ($$self{POINTER} >= scalar@{$$self{ARTICLES}} - 1) { 
    "421 No Next Article"; 
  } else { $$self{POINTER}++; $self->stat; }
} 
# post
sub post { 
  my ($self, $fh) = @_; 	return undef unless $fh;
  print $fh "340 Send article to be posted\n";
  my @lines;
  while (defined (my $line = <$fh>)) { 
    $line =~ s/(\r?\n|\n?\r)$//g;	# chomp wasn't working
    last if $line =~ /^\.$/;
    CORE::push @lines, $line; 
  }
  my $article = News::Article->new(\@lines) 
		|| return "441 Posting Failed (Article was Empty)";
  $article->write(\*STDOUT) if $DEBUG;
  $article->set_headers('newsgroups',
        $self->_fix_groups($article->header('newsgroups')) );
  $article->add_message_id;  $article->add_date;
  my $success = 0;  my @problems;
  foreach my $server (@{$self->newsservers}) {
    my $nntp = $server->nntp || next;
    my $name = $server->name;
    next unless $server->postok;
    local $@;
    warn "Posting to $name\n";
    eval { $article->post($nntp) } ;
    if ($@) {
      chomp $@;
      warn "Error in posting to $name: $@\n";
      CORE::push @problems, "$name: $@";
    } else {
      $success++;
    }
  }
  $success ? "240 Article Posted to $success servers" 
	   : "441 Was unable to post to any news servers - " . join(', ', @problems);
}

=item slave ()

Not yet implemented

=cut

sub slave () { } 

# stat [MessageID|Number]
sub stat {
  my ($self, $id) = @_;
  return $self->nogroupselect() unless (defined $$self{GROUP});
  my ($number, $messageid) = $self->_stat($id);
     $number ||= 0;

  if ($messageid) { return "223 $number $messageid"; } 
  elsif ($number) { return "423 No Such Article In Group"; } 
  else            { return "430 No Such Article"; }
}

=item xgtitle ( GROUP_PATTERN )

Not yet implemented

=cut

sub xgtitle { }

=item xhdr ( RANGE | ID )

Not yet implemented

=cut

sub xhdr { }

=item xover ( RANGE ) 

Returns the overview information from the given C<RANGE>.  

=cut

sub xover { 
  my ($self, $range) = @_;
  return $self->nogroupselect() unless (defined $$self{GROUP});
  
  my $server  = $$self{SERVER} || return undef;
  my $hash    = $server->xover($range) || return undef; 
  my @return = "224 overview data follows";
  foreach (sort { $a <=> $b } keys %{$hash}) { 
    CORE::push @return, join("\t", $_, @{$$hash{$_}}); 
  }
  CORE::push @return, ".";
	
  join("\n", @return);
}

=item xpat ( HEADER, RANGE | ID, PATTERN [, PATTERN [, PATTERN ]] )

Not yet implemented

=cut

sub xpat { }

=item xpath ( ID )

Not yet implemented

=cut

sub xpath { }

=item quit ( FILEHANDLE ) 

Close C<FILEHANDLE> and quit.

=cut

sub quit { 
  my ($self, $fh) = @_;
  return undef unless defined fileno($fh);
  print $fh "205 Goodbye\n";
  close $fh;
}

# Error messages
sub nosuchgroup { my $group = shift || "";  return "411 No such group $group" }
sub badcommand      { "500 Syntax Error or Unknown Command" }
sub nogroupselect   { "512 No Group Selected" }
sub badarticlenumber { "423 Bad article number"; }

###############################################################################
##### INTERNAL AND HELPER FUNCTIONS ###########################################
###############################################################################

### DESTROY
# When the object goes away, make sure that disconnect() is called.
sub DESTROY { shift->disconnect() }

### _fix_groups ( LINE )
# Takes a Newsgroups: line, and takes out everything after the '@' in each
# group.  This is important for translating back to the real world's groups.
# Hopefully this won't break PGPMoose and such too badly; I don't think they
# follow Newsgroups:...
sub _fix_groups {
  my ($self, $line) = @_;  
  my @groups = split(',', $line || "");
  map { s/^\s*(\S+)(@\S*)\s*$/$1/ } @groups;
  join(',', @groups);
}

### _group ( GROUP )
# Loads GROUP from the appropriate server
sub _group {
  my ($self, $group) = @_;   return undef unless $group;
  if ($group =~ /^(.*)@(.*)$/) {	# Group we created 
    my $newsgroup  = $1;  my $servername = $2;
    foreach my $server (@{$$self{NEWSSERVERS}}) {
      next unless $server;
      my $newsserver = $server->name;
      return ($newsgroup, $server) if ($servername eq $newsserver);
    }
    return undef;
  } else {				# Group we're proxying
    my $newsgroup = $group;
    # Figure out which server has the first feed of this group.  
    foreach my $server (@{$$self{NEWSSERVERS}}) {
      next unless ($server && $server->connected);
      $server->group($newsgroup) ? return ($newsgroup, $server) : next;
    }
  }
  return undef;
}

### _list_newsgroups ( [PATTERN] )
# Creates the newsgroups list out of the newsgroups values.  
sub _list_newsgroups {
  my ($self, $pattern) = @_;
      $pattern ||= '*';
  my @return = "215 Newsgroups Follow";
  my %fullhash;
  foreach (@{$$self{'NEWSSERVERS'}}) {
    my $server = $_->server;
    my $hash   = $_->newsgroups($pattern);
    foreach (keys %{$hash}) {
      $fullhash{$_} ||= $$hash{$_};
      CORE::push @return, "$_\@$server $$hash{$_}";
    }
  }
  foreach (keys %fullhash) { CORE::push @return, "$_ $fullhash{$_}"; }
  CORE::push @return, ".";
  wantarray ? @return : join($NEWLINE, @return);
}

### _list_active ( [PATTERN] )
# Creates the active list out of the active values.  
sub _list_active {
  my ($self, $pattern) = @_;
      $pattern ||= '*';  
  my @return = "215 Newsgroups Follow .";
  my %fullhash;
  foreach (@{$$self{'NEWSSERVERS'}}) {
    my $name   = $_->name || "";
    my $hash   = $_->active($pattern) || {};
    foreach (sort keys %{$hash}) {
      next unless $_;  
      CORE::push @return, "$_\@$name @{$$hash{$_}}";
      $fullhash{$_} ||= "@{$$hash{$_}}";
    }
  }
  foreach (sort keys %fullhash) { CORE::push @return, "$_ $fullhash{$_}"; }
  CORE::push @return, ".";
  wantarray ? @return : join($NEWLINE, @return);
}

### _list_active_times ( [PATTERN] )
# Creates the active.times list out of the active.times values.  
sub _list_active_times {
  my ($self, $pattern) = @_;
      $pattern ||= '*';
  my @return = "215 Group Creations";
  my %fullhash;
  foreach (@{$$self{'NEWSSERVERS'}}) {
    my $server = $_->name;
    my $hash   = $_->active_times();
    foreach (sort keys %{$hash}) {
      next unless $_;
      CORE::push @return, "$_\@$server @{$$hash{$_}}[0]";
      $fullhash{$_} ||= "@{$$hash{$_}}[0]";
    }
  }
  foreach (sort keys %fullhash) { CORE::push @return, "$_ $fullhash{$_}"; }
  CORE::push @return, ".";
  wantarray ? @return : join($NEWLINE, @return);
}

### _listgroup ( [GROUP] , SERVER ) 
# Returns the listgroup information.  GROUP can be 'undef' if you'd like.
sub _listgroup {
  my ($self, $group, $server) = @_;  return undef unless $server;
  $$self{ARTICLES} = $server->listgroup($group) || []; 
  $$self{POINTER} = 0;
  wantarray ? @{$$self{ARTICLES}} : $$self{ARTICLES};
}

### _stat ( [ID] )
# Get the stat information on C<ID>, and set $POINTER if necessary.
sub _stat {
  my ($self, $id) = @_;

  # Get the various important values for later use
  my $pointer = $$self{POINTER};  my @articles = @{$$self{ARTICLES}};
  my $server  = $$self{SERVER};   my $group = $$self{GROUP};
  my @servers = @{$$self{NEWSSERVERS}};
   
  if (!(defined $id)) {		# No ID given at all -> last result
    return (-1, undef) unless ($pointer >= 0);
    if (defined $pointer && scalar @articles && defined $server) {
      # my $nntp = $server->nntp || return (undef, undef);
      my $messageid   = $server->nntpstat($articles[$pointer]);
      return ($articles[$pointer], $messageid) if $messageid;
    } elsif (scalar @articles && defined $server) {
      return (1, undef)
    } else {
      return (undef, undef);
    }
  } elsif ($id =~ /^\d+$/) {	# Numeric ID -> in a group
    # If we're not in a group, then just stop now.
    return (undef, undef) unless ( scalar @articles && defined $server );
    # There's two choices here - do it locally, or do it by the 'net.  The
    # latter is more computationally efficient but requires network accesses.  
    for (my $i = 0; $i < scalar @articles; $i++) {
      if ($articles[$i] eq $id) {
        my $messageid = $server->nntpstat($articles[$i]) || next;
        $$self{POINTER} = $i if $messageid;
        return ($id, $messageid) if $messageid;
      }
    }
    $$self{POINTER} = undef;
    return ($id, undef);
  } else {			# It's a full message ID
    foreach ($server, @servers) {
      next unless $_;  
      my $messageid   = $_->nntpstat($id);
      return (0, $messageid) if $messageid;
    }
    return (undef, undef);
  }
}

### _article ( ID [, NID] )
# Downloads the given ID from all of the object's news servers.  
sub _article {
  my ($self, $id, $nid) = @_;  $id ||= "";

  # If the given ID is numeric or not given, then try to find and 
  # load the appropriate message-ID.  If that doesn't work, then it 
  # was a bad number.
  if (!$id || $id =~ /^\d+$/) { 	# Non-existant or numeric 
    my ($number, $mid) = $self->_stat($id);  
    return "" if ($id && $mid && ($id eq $mid));	# TESTING
    $self->_group($$self{GROUP});
    return $self->_article( $mid, $id ) || $self->badarticlenumber;
  } 

  warn "Looking for article $id\n" if $DEBUG;
  
  # Search through all of the news servers in order for the full 
  # message-ID.  
  foreach my $server (@{$$self{NEWSSERVERS}}) {
    my $article = News::Article->new($server->article($id));
    return $article if $article;
  }
  # If all else fails, go with the numeric ID (if possible)
  my $server  = $$self{SERVER} || return undef;
  my $article = News::Article->new($server->article($nid));
  $article ? $article : undef;
}

### _open_socket ( PORT [, MAXCONN] )
# Build a socket.  Code taken from Programming Perl, 3rd Edition.
sub _open_socket {
  my ($self, $port, $maxconn) = @_;
  return undef unless $port;
  
  # make the socket
  socket(SERVER, PF_INET, SOCK_STREAM, getprotobyname('tcp'));  
  
  # so we can restart our server quickly
  setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, 1);
  
  # build up my socket address
  unless (bind (SERVER, sockaddr_in($port, INADDR_ANY) ) ) {
    warn "Couldn't bind to port $port: $!\n"; 
    return undef;
  }
  
  # establish a queue for incoming connections 
  unless (listen(SERVER, $maxconn || $MAXCONN || SOMAXCONN) ) {
    warn "Couldn't listen on port $port: $!\n";
    return undef;
  }
  warn "Listening on port $port\n" if $DEBUG;
  
  \*SERVER;
}

=back

=head1 REQUIREMENTS

C<News::Article>, C<Net::NNTP>

=head1 NOTES

This documentation is basically functional, but not much more.  

=head1 SEE ALSO

L<Net::NNTP>, L<Net::NNTP::Client>, L<newsproxy.pl>

=head1 TODO

Write better documentation.  Write other news server types that aren't
Net::NNTP::Client.  Implement the rest of the functions that I haven't
gotten around to yet.  Speed it up.

=head1 AUTHOR

Written by Tim Skirvin <tskirvin@killfile.org>.

=head1 COPYRIGHT

Copyright 2000-2002 by Tim Skirvin <tskirvin@killfile.org>.  This code may be
redistributed under the same terms as Perl itself.

=cut

1;

# Version History
# v0.5a - Thu Nov  9 18:03:58 CST 2000
#   Commenting in progress.  This thing still needs some serious work to
#   make it pretty, though.  
# v0.51a - Tue Apr 24 15:56:49 CDT 2001
#   Worked around a bug from Net::NNTP where '^..' is turned into '^.'.  
# v0.52a - Mon Jan 28 11:30:32 CST 2002
#   Replaced push() with CORE::push().  Started sorting the active and
#   active_times() outputs.  Changed to variable EOL string.  Fixed some 
#   bugs in _list_active and the line with returning arrays.
# v0.53a - Wed Jan 30 09:32:27 CST 2002
#   Fixed article() to have uniform newlines.
# v0.54		Thu Apr 22 11:44:01 CDT 2004 
### No real changes, just internal layout changes.
