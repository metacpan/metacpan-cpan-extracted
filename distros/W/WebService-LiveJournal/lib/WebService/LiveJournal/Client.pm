package WebService::LiveJournal::Client;

use strict;
use warnings;
use v5.10;
use overload '""' => \&as_string;
use Digest::MD5 qw(md5_hex);
use RPC::XML;
use RPC::XML::Client;
use WebService::LiveJournal::FriendList;
use WebService::LiveJournal::FriendGroupList;
use WebService::LiveJournal::Event;
use WebService::LiveJournal::EventList;
use WebService::LiveJournal::Tag;
use HTTP::Cookies;

# ABSTRACT: Interface to the LiveJournal API
our $VERSION = '0.08'; # VERSION


my $zero = new RPC::XML::int(0);
my $one = new RPC::XML::int(1);
our $lineendings_unix = new RPC::XML::string('unix');
my $challenge = new RPC::XML::string('challenge');
our $error;
our $error_request;

$RPC::XML::ENCODING = 'utf-8';  # uh... and WHY??? is this a global???


sub new    # arg: server, port, username, password, mode
{
  my $ob = shift;
  my $class = ref($ob) || $ob;
  my $self = bless {}, $class;
  
  my %arg = @_;
  
  my $server = $self->{server} = $arg{server} // 'www.livejournal.com';
  my $domain = $server;
  $domain =~ s/^([A-Za-z0-9]+)//;
  $self->{domain} = $domain;
  my $port = $self->{port} = $arg{port} || 80;
  $server .= ":$port" if $port != 80;
  my $client = $self->{client} = new RPC::XML::Client("http://$server/interface/xmlrpc");
  $self->{flat_url} = "http://$server/interface/flat";
  my $cookie_jar = $self->{cookie_jar} = new HTTP::Cookies;
  $client->useragent->cookie_jar($cookie_jar);
  $client->useragent->default_headers->push_header('X-LJ-Auth' => 'cookie');

  $self->{mode} = $arg{mode} // 'cookie';  # can be cookie or challenge

  my $username = $self->{username} = $arg{username};
  my $password = $arg{password};
  $self->{password} = $password if $self->{mode} ne 'cookie';
  
  $self->{auth} = [ ver => $one ];
  $self->{flat_auth} = [ ver => 1 ];
  
  if($self->{mode} eq 'cookie')
  {
  
    my $response = $self->send_request('getchallenge');
    return unless defined $response;
    my $auth_challenge = $response->value->{challenge};
    my $auth_response = md5_hex($auth_challenge, md5_hex($password));
  
    push @{ $self->{auth} }, username => new RPC::XML::string($username);
    push @{ $self->{flat_auth} }, user => $username;

    $response = $self->send_request('sessiongenerate',
            auth_method => $challenge,
            auth_challenge => new RPC::XML::string($auth_challenge),
            auth_response => new RPC::XML::string($auth_response),
    );

    return unless defined $response;

    my $ljsession = $self->{ljsession} = $response->value->{ljsession};
    $self->set_cookie(ljsession => $ljsession);  
    push @{ $self->{auth} }, auth_method => new RPC::XML::string('cookie');
    push @{ $self->{flat_auth} }, auth_method => 'cookie';
  
  }
  elsif($self->{mode} eq 'challenge')
  {
    push @{ $self->{auth} }, username => new RPC::XML::string($username);
    push @{ $self->{flat_auth} }, user => $username;
  }

  my $response = $self->send_request('login'
          #getmoods => $zero,
          #getmenus => $one,
          #getpickws => $one,
          #getpickwurls => $one,
  );
  
  return unless defined $response;
  
  my $h = $response->value;
  return $self->_set_error($h->{faultString}) if defined $h->{faultString};
  return $self->_set_error("unknown LJ error " . $h->{faultCode}->value) if defined $h->{faultCode};
  
  $self->{userid} = $h->{userid};
  $self->{fullname} = $h->{fullname};
  $self->{usejournals} = $h->{usejournals} || [];
  my $fastserver = $self->{fastserver} = $h->{fastserver};
  
  if($fastserver)
  {
    $self->set_cookie(ljfastserver => 1);
  }
  
  if($h->{friendgroups})
  {
    my $fg = $self->{cachefriendgroups} = new WebService::LiveJournal::FriendGroupList(response => $response);
  }
  
  $self->{message} = $h->{message};
  return $self;
}


foreach my $name (qw( server username port userid fullname usejournals fastserver cachefriendgroups message cookie_jar ))
{
  eval qq{ sub $name { shift->{$name} } };
  die $@ if $@;
}

sub useragent { $_[0]->{client}->useragent }


sub create_event
{
  my $self = shift;
  my $event = new WebService::LiveJournal::Event(client => $self, @_);
  $event;
}

# legacy
sub create { shift->create_event(@_) }


sub get_events
{
  my $self = shift;
  my @list;
  my $selecttype = shift || 'lastn';
  push @list, selecttype => new RPC::XML::string($selecttype);

  my %arg = @_;

  if($selecttype eq 'syncitems')
  {
    push @list, lastsync => new RPC::XML::string($arg{lastsync}) if defined $arg{lastsync};
  }
  elsif($selecttype eq 'day')
  {
    unless(defined $arg{day} && defined $arg{month} && defined $arg{year})
    {
      return $self->_set_error('attempt to use selecttype=day without providing day!');
    }
    push  @list, 
      day   => new RPC::XML::int($arg{day}),
      month  => new RPC::XML::int($arg{month}),
      year  => new RPC::XML::int($arg{year});
  }
  elsif($selecttype eq 'lastn')
  {
    push @list, howmany => new RPC::XML::int($arg{howmany}) if defined $arg{howmany};
    push @list, howmany => new RPC::XML::int($arg{max}) if defined $arg{max};
    push @list, beforedate => new RPC::XML::string($arg{beforedate}) if defined $arg{beforedate};
  }
  elsif($selecttype eq 'one')
  {
    my $itemid = $arg{itemid} || -1;
    push @list, itemid => new RPC::XML::int($itemid);
  }
  else
  {
    return $self->_set_error("unknown selecttype: $selecttype");
  }
  
  push @list, truncate => new RPC::XML::int($arg{truncate}) if $arg{truncate};
  push @list, prefersubject => $one if $arg{prefersubject};
  push @list, lineendings => $lineendings_unix;
  push @list, usejournal => RPX::XML::string($arg{usejournal}) if $arg{usejournal};
  push @list, usejournal => RPX::XML::string($arg{journal}) if $arg{journal};

  my $response = $self->send_request('getevents', @list);
  return unless defined $response;
  if($selecttype eq 'one')
  {
    return unless @{ $response->value->{events} } > 0;
    return new WebService::LiveJournal::Event(client => $self, %{ $response->value->{events}->[0] });
  }
  else
  {
    return new WebService::LiveJournal::EventList(client => $self, response => $response);
  }
}

# legacy
sub getevents { shift->get_events(@_) }


sub get_event
{
  my $self = shift;
  my %args = @_ == 1 ? (itemid => shift) : (@_);
  $self->get_events('one', %args);
}

# legacy
sub getevent { shift->get_event(@_) }


sub sync_items
{
  my $self = shift;
  my $cb = sub {};
  $cb = pop if ref($_[-1]) eq 'CODE';
  my %arg = @_;
  
  my $return_time;
  
  my @req_args = ();
  if(defined $arg{last_sync})
  {
    @req_args = ( lastsync => $arg{last_sync} );
    $return_time = $arg{last_sync};
  }
  
  eval {
    while(1)
    {
      my $response = $self->send_request('syncitems', @req_args);
      last unless defined $response;
      my $count = $response->value->{count};
      my $total = $response->value->{total};
      foreach my $item (@{ $response->value->{syncitems} })
      {
        unless($item->{item} =~ /^(.)-(\d+)$/)
        {
          die 'internal error: ' . $item->{item} . ' does not match';
        }
        $cb->($item->{action}, $1, $2);
        $return_time = $item->{time};
      }
      last if $count == $total;
      @req_args = ( lastsync => $arg{return_time} );
    };
  };
  $WebService::LiveJournal::Client::error = $@ if $@;
  return $return_time;
}


sub get_friends
{
  my $self = shift;
  my %arg = @_;
  my @list;
  push @list, friendlimit => new RPC::XML::int($arg{friendlimit}) if defined $arg{friendlimit};
  push @list, friendlimit => new RPC::XML::int($arg{limit}) if defined $arg{limit};
  push @list, includefriendof => 1, includegroups => 1 if $arg{complete};
  my $response = $self->send_request('getfriends', @list);
  return unless defined $response;
  if($arg{complete})
  {
    return (new WebService::LiveJournal::FriendList(response_list => $response->value->{friends}),
      new WebService::LiveJournal::FriendList(response_list => $response->value->{friendofs}),
      new WebService::LiveJournal::FriendGroupList(response => $response),
    );
  }
  else
  {
    return new WebService::LiveJournal::FriendList(response => $response);
  }
}

sub getfriends { shift->get_friends(@_) }


sub get_friend_of
{
  my $self = shift;
  my %arg = @_;
  my @list;
  push @list, friendoflimit => new RPC::XML::int($arg{friendoflimit}) if defined $arg{friendoflimit};
  push @list, friendoflimit => new RPC::XML::int($arg{limit}) if defined $arg{limit};
  my $response = $self->send_request('friendof', @list);
  return unless defined $response;
  return new WebService::LiveJournal::FriendList(response => $response);
}

sub friendof { shift->get_friend_of(@_) }


sub get_friend_groups
{
  my $self = shift;
  my $response = $self->send_request('getfriendgroups');
  return unless defined $response;
  return new WebService::LiveJournal::FriendGroupList(response => $response);
}

sub getfriendgroups { shift->get_friend_groups(@_) }


sub get_user_tags
{
  my($self, $journal_name) = @_;
  my @request = ('getusertags');
  push @request, usejournal => RPC::XML::string->new($journal_name)
    if defined $journal_name;
  my $response = $self->send_request(@request);
  return unless defined $response;
  return map { WebService::LiveJournal::Tag->new($_) } @{ $response->value->{tags} };
}


sub console_command
{
  my $self = shift;
  
  my $response = $self->send_request('consolecommand',
    commands => RPC::XML::array->new(
      RPC::XML::array->new(
        map { RPC::XML::string->new($_) } @_
      ),
    ),
  );
  return unless defined $response;
  return $response->value->{results}->[0]->{output};
}


sub batch_console_commands
{
  my $self = shift;
  my @commands;
  my @cb;
  for(0..$#_)
  {
    if($_ % 2)
    { push @cb, $_[$_] }
    else
    { push @commands, RPC::XML::array->new(map { RPC::XML::string->new($_) } @{ $_[$_] }) }
  }
  
  my $response = $self->send_request('consolecommand',
    commands => RPC::XML::array->new(@commands)
  );
  return unless defined $response;

  # also returned is 'success' but as far as I can tell it is always
  # 1, even if the command doesn't exist.  so we are ignoring it.
  
  foreach my $output (map { $_->{output} } @{ $response->value->{results} })
  {
    my $cb = shift @cb;
    $cb->(@$output);
  }
  
  return 1;
}


sub set_cookie
{
  my $self = shift;
  my $key = shift;
  my $value = shift;

  $self->cookie_jar->set_cookie(
        0,                   # version
        $key => $value,      # key => value
        '/',                 # path
        $self->{domain},     # domain
        $self->port,         # port
        1,                   # path_spec
        0,                   # secure
        60*60*24,            # maxage
        0,                   # discard
  );
}


sub send_request
{
  my $self = shift;
  $self->_clear_error;
  my $count = $self->{count} || 1;
  my $procname = shift;
        
  my @challenge;
  if($self->{mode} eq 'challenge')
  {
    my $response = $self->{client}->send_request('LJ.XMLRPC.getchallenge');
    if(ref $response)
    {
      if($response->is_fault)
      {
        my $string = $response->value->{faultString};
        my $code = $response->value->{faultCode};
        $self->_set_error("$string ($code) on LJ.XMLRPC.getchallenge");
        return;
      }
      # else, stuff worked fall through 
    }
    else
    {
      if($count < 5 && $response =~ /HTTP server error: Method Not Allowed/i)
      {
        $self->{count} = $count+1;
        print STDERR "retry ($count)\n";
        sleep 10;
        my $response = $self->send_request($procname, @_);
        $self->{count} = $count;
        return $response;
      }
      return $self->_set_error($response);
    }

    # this is where we fall through down to from above
    my $auth_challenge = $response->value->{challenge};
    my $auth_response = md5_hex($auth_challenge, md5_hex($self->{password}));
    @challenge = (
      auth_method => $challenge,
      auth_challenge => new RPC::XML::string($auth_challenge),
      auth_response => new RPC::XML::string($auth_response),
    );
  }

  my $request = new RPC::XML::request(
      "LJ.XMLRPC.$procname",
      new RPC::XML::struct(
        @{ $self->{auth} },
        @challenge,
        @_,
      ),
  );

  #use Test::More;
  #use XML::LibXML;
  #use XML::LibXML::PrettyPrint;
  #my $xml = XML::LibXML->new->parse_string($request->as_string);
  #my $pp = XML::LibXML::PrettyPrint->new(indent_string => '  ')->pretty_print($xml);
  #note 'send request:';
  #note $xml->toString;

  my $response = $self->{client}->send_request($request);
  
  #my $xml = XML::LibXML->new->parse_string($response->as_string);
  #my $pp = XML::LibXML::PrettyPrint->new(indent_string => '  ')->pretty_print($xml);
  #note 'recv response:';
  #note $xml->toString;
  
  if(ref $response)
  {
    if($response->is_fault)
    {
      my $string = $response->value->{faultString};
      my $code = $response->value->{faultCode};
      $self->_set_error("$string ($code) on LJ.XMLRPC.$procname");
      $error_request = $request;
      return;
    }
    return $response;
  }
  else
  {
    if($count < 5 && $response =~ /HTTP server error: Method Not Allowed/i)
    {
      $self->{count} = $count+1;
      print STDERR "retry ($count)\n";
      sleep 10;
      my $response = $self->send_request($procname, @_);
      $self->{count} = $count;
      return $response;
    }
    return $self->_set_error($response);
  }
}

sub _post
{
  my $self = shift;
  my $ua = $self->{client}->useragent;
  my %arg = @_;
  #use Test::More;
  #note "====\nOUT:\n";
  #foreach my $key (keys %arg)
  #{
  #  note "$key=$arg{$key}\n";
  #}
  my $http_response = $ua->post($self->{flat_url}, \@_);
  return $self->_set_error("HTTP Error: " . $http_response->status_line) unless $http_response->is_success;
  
  my $response_text = $http_response->content;
  my @list = split /\n/, $response_text;
  my %h;
  #note "====\nIN:\n";
  while(@list > 0)
  {
    my $key = shift @list;
    my $value = shift @list;
    #note "$key=$value\n";
    $h{$key} = $value;
  }
  
  return $self->_set_error("LJ Protocol error, server didn't return a success value") unless defined $h{success};
  return $self->_set_error("LJ Protocol error: $h{errmsg}") if $h{success} ne 'OK';
    
  return \%h;
}

sub as_string
{
  my $self = shift;
  my $username = $self->username;
  my $server = $self->server;
  "[ljclient $username\@$server]";
}

sub findallitemid
{
  my $self = shift;
  my %arg = @_;
  my $response = $self->send_request('syncitems');
  die $error unless defined $response;
  my $count = $response->value->{count};
  my $total = $response->value->{total};
  my $time;
  my @list;
  while(1)
  {
    #print "$count/$total\n";
    foreach my $item (@{ $response->value->{syncitems} })
    {
      $time = $item->{time};
      my $id = $item->{item};
      my $action = $item->{action};
      if($id =~ /^L-(\d+)$/)
      {
        push @list, $1;
      }
    }
    
    last if $count == $total;

    $response = $self->send_request('syncitems', lastsync => $time);
    die $error unless defined $response;
    $count = $response->value->{count};
    $total = $response->value->{total};
  }

  return @list;
}


sub send_flat_request
{
  my $self = shift;
  $self->_clear_error;
  my $count = $self->{count} || 1;
  my $procname = shift;
  my $ua = $self->{client}->useragent;

  my @challenge;
  if($self->{mode} eq 'challenge')
  {
    my $h = _post($self, mode => 'getchallenge');
    return unless defined $h;
    my %h = %{ $h };

    my $auth_challenge = $h{challenge};

    my $auth_response = md5_hex($auth_challenge, md5_hex($self->{password}));
    @challenge = (
      auth_method => 'challenge',
      auth_challenge => $auth_challenge,
      auth_response => $auth_response,
    );
  }
  
  return _post($self, 
    mode => $procname, 
    @{ $self->{flat_auth} },
    @challenge,
    @_
  );
}

sub _set_error
{
  my($self, $value) = @_;
  $error = $value;
  return;
}

sub _clear_error
{
  undef $error;
}


sub error { $error }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::LiveJournal::Client - Interface to the LiveJournal API

=head1 VERSION

version 0.08

=head1 SYNOPSIS

new interface

 use WebService::LiveJournal;
 my $client = WebService::LiveJournal->new( username => 'foo', password => 'bar' );

same thing with the old interface

 use WebService::LiveJournal::Client;
 my $client = WebService::LiveJournal::Client->new( username => 'foo', password => 'bar' );
 die "connection error: $WebService::LiveJournal::Client::error" unless defined $client;

See L<WebService::LiveJournal::Event> for creating/updating LiveJournal events.

See L<WebService::LiveJournal::Friend> for making queries about friends.

See L<WebService::LiveJournal::FriendGroup> for getting your friend groups.

=head1 DESCRIPTION

This is a client class for communicating with LiveJournal using its API.  It is different
from the other LJ modules on CPAN in that it originally used the XML-RPC API.  It now
uses a hybrid of the flat and XML-RPC API to avoid bugs in some LiveJournal deployments.

There are two interfaces:

=over 4

=item L<WebService::LiveJournal>

The new interface, where methods throw an exception on error.

=item L<WebService::LiveJournal::Client>

The legacy interface, where methods return undef on error and
set $WebService::LiveJournal::Client::error

=back

It is recommended that for any new code that you use the new interface.

=head1 CONSTRUCTOR

=head2 new

 my $client = WebService::LiveJournal::Client->new( %options )

Connects to a LiveJournal server using the host and user information
provided by C<%options>.

Signals an error depending on the interface
selected by throwing an exception or returning undef.

=head3 options

=over 4

=item server

The server hostname, defaults to www.livejournal.com

=item port

The server port, defaults to 80

=item username [required]

The username to login as

=item password [required]

The password to login with

=item mode

One of either C<cookie> or C<challenge>, defaults to C<cookie>.

=back

=head1 ATTRIBUTES

These attributes are read-only.

=head2 server

The name of the LiveJournal server

=head2 port

The port used to connect to LiveJournal with

=head2 username

The username used to connect to LiveJournal

=head2 userid

The LiveJournal userid of the user used to connect to LiveJournal.
This is an integer.

=head2 fullname

The fullname of the user used to connect to LiveJournal as LiveJournal understands it

=head2 usejournals

List of shared/news/community journals that the user has permission to post in.

=head2 message

Message that should be displayed to the end user, if present.

=head2 useragent

Instance of L<LWP::UserAgent> used to connect to LiveJournal

=head2 cookie_jar

Instance of L<HTTP::Cookies> used to connect to LiveJournal with

=head2 fastserver

True if you have a paid account and are entitled to use the
fast server mode.

=head1 METHODS

=head2 create_event

 $client->create_event( %options )

Creates a new event and returns it in the form of an instance of
L<WebService::LiveJournal::Event>.  This does not create the 
event on the LiveJournal server itself, until you use the 
C<update> methods on the event.

C<%options> contains a hash of attribute key, value pairs for
the new L<WebService::LiveJournal::Event>.  The only required
attributes are C<subject> and C<event>, though you may set these
values after the event is created as long as you set them
before you try to C<update> the event.  Thus this:

 my $event = $client->create(
   subject => 'a new title',
   event => 'some content',
 );
 $event->update;

is equivalent to this:

 my $event = $client->create;
 $event->subject('a new title');
 $event->event('some content');
 $event->update;

This method signals an error depending on the interface
selected by throwing an exception or returning undef.

=head2 get_events

 $client->get_events( $select_type, %query )

Selects events from the LiveJournal server.  The actual C<%query>
parameter requirements depend on the C<$select_type>.

Returns an instance of L<WebService::LiveJournal::EventList>.

Select types:

=over 4

=item syncitems

This query mode can be used to sync all entries with multiple calls.

=over 4

=item lastsync

The date of the last sync in the format of C<yyyy-mm-dd hh:mm:ss>

=back

=item day

This query can be used to fetch all the entries for a particular day.

=over 4

=item year

4 digit integer

=item month

1 or 2 digit integer, 1-31

=item day

integer 1-12 

=back

=item lastn

Fetch the last n events from the LiveJournal server.

=over 4

=item howmany

integer, default = 20, max = 50

=item beforedate

date of the format C<yyyy-mm-dd hh:mm:ss>

=back

=back

This method signals an error depending on the interface
selected by throwing an exception or returning undef.

=head2 get_event

 $client->get_event( $itemid )

Given an C<itemid> (the internal LiveJournal identifier for an event).

This method signals an error depending on the interface
selected by throwing an exception or returning undef.

=head2 sync_items

 $client->sync_items( $cb )
 $client->sync_items( last_sync => $time, $cb )

Fetch all of the items which have been created/modified since the last sync.
If C<last_sync =E<gt> $time> is not provided then it will fetch all events.
For each item that has been changed it will call the code reference C<$cb>
with three arguments:

 $cb->($action, $type, $id)

=over 4

=item action

One of C<create> or C<update>

=item type

For "events" (journal entries) this is C<L>

=item id

The internal LiveJournal server id for the item.  An integer.
For events, the actual event can be fetched using the C<get_event>
method.

=back

If the callback throws an exception, then no more entries will be processed.
If the callback does not throw an exception, then the next item will be
processed.

This method returns the time of the last entry successfully processed, which
can be passed into C<sync_item> the next time to only get the items that have
changed since the first time.

Here is a broad example:

 # first time:
 my $time = $client->sync_items(sub {
   my($action, $type, $id) = @_;
   if($type eq 'L')
   {
     my $event = $client->get_item($id);
     # ...
     if(error condition)
     {
       die 'error happened';
     }
   }
 });
 
 # if an error happened during the sync
 my $error = $client->error;
 
 # next time:
 $time = $client->sync_items(last_sync => $time, sub {
   ...
 });

Because the C<syncitems> rpc that this method depends on
can make several requests before it completes it can fail
half way through.  If this happens, you can restart where
the last successful item was processed by passing the
return value back into C<sync_items> again.  You can tell
that C<sync_item> completed without error because the 
C<$client-E<gt>error> accessor should return a false value.

=head2 get_friends

 $client->get_friends( %options )

Returns friend information associated with the account with which you are logged in.

=over 4

=item complete

If true returns your friends, stalkers (users who have you as a friend) and friend groups

 # $friends is a WS::LJ::FriendList containing your friends
 # $friend_of is a WS::LJ::FriendList containing your stalkers
 # $groups is a WS::LJ::FriendGroupList containing your friend groups
 my($friends, $friend_of, $groups) = $client-E<gt>get_friends( complete => 1 );

If false (the default) only your friends will be returned

 # $friends is a WS::LJ::FriendList containing your friends
 my $friends = $client-E<gt>get_friends;

=item friendlimit

If set to a numeric value greater than zero, this mode will only return the number of results indicated. 

=back

=head2 get_friends_of

 $client->get_friend_of( %options )

Returns the list of users that are a friend of the logged in account.

Returns an instance of L<WebService::LiveJournal::FriendList>, a list of
L<WebService::LiveJournal::Friend>.

Options:

=over 4

=item friendoflimit

If set to a numeric value greater than zero, this mode will only return the number of results indicated

=back

=head2 get_friend_groups

 $client->get_friend_groups

Returns your friend groups.  This comes as an instance of
L<WebService::LiveJournal::FriendGroupList> that contains
zero or more instances of L<WebService::LiveJournal::FriendGroup>.

=head2 get_user_tags

 $client->get_user_tags;
 $client->get_user_tags( $journal_name );

Fetch the tags associated with the given journal, or the users journal
if not specified.  This method returns a list of zero or more
L<WebService::LiveJournal::Tag> objects.

=head2 console_command

 $client->console_command( $command, @arguments )

Execute the given console command with the given arguments on the
LiveJournal server.  Returns the output as a list reference.
Each element in the list represents a line out output and consists
of a list reference containing the type of output and the text
of the output.  For example:

 my $ret = $client->console_command( 'print', 'hello world' );

returns:

 [
   [ 'info',    "Welcome to 'print'!" ],
   [ 'success', "hello world" ],
 ]

=head2 batch_console_commands

 $client->batch_console_commands( $command1, $callback);
 $client->batch_console_commands( $command1, $callback, [ $command2, $callback, [ ... ] );

Execute a list of commands on the LiveJournal server in one request. Each command is a list reference. Each callback 
associated with each command will be called with the results of that command (in the same format returned by 
C<console_command> mentioned above, except it is passed in as a list instead of a list reference).  Example:

 $client->batch_console_commands(
   [ 'print', 'something to print' ],
   sub {
     my @output = @_;
     ...
   },
   [ 'print', 'something else to print' ],
   sub {
     my @output = @_;
     ...
   },
 );

=head2 set_cookie

 $client->set_cookie( $key => $value )

This method allows you to set a cookie for the appropriate security and expiration information.
You shouldn't need to call it directly, but is available here if necessary.

=head2 send_request

 $client->send_request( $procname, @arguments )

Make a low level request to LiveJournal with the given
C<$procname> (the rpc procedure name) and C<@arguments>
(should be L<RPC::XML> types).

On success returns the appropriate L<RPC::XML> type
(usually RPC::XML::struct).

This method signals an error depending on the interface
selected by throwing an exception or returning undef.

=head2 send_flat_request

 $client->send_flat_request( $procname, @arguments )

Sends a low level request to the LiveJournal server using the flat API,
with the given C<$procname> (the rpc procedure name) and C<@arguments>.

On success returns the appropriate response.

This method signals an error depending on the interface
selected by throwing an exception or returning undef.

=head2 error

 $client->error

Returns the last error.  This just returns
$WebService::LiveJournal::Client::error, so it
is still a global, but is a slightly safer shortcut.

 my $event = $client->get_event($itemid) || die $client->error;

It is still better to use the newer interface which throws
an exception for any error.

=head1 EXAMPLES

These examples are included with the distribution in its 'example' directory.

Here is a simple example of how you would login/authenticate with a 
LiveJournal server:

 use strict;
 use warnings;
 use WebService::LiveJournal;
 
 print "user: ";
 my $user = <STDIN>;
 chomp $user;
 print "pass: ";
 my $password = <STDIN>;
 chomp $password;
 
 my $client = WebService::LiveJournal->new(
   server => 'www.livejournal.com',
   username => $user,
   password => $password,
 );
 
 print "$client\n";
 
 if($client->fastserver)
 {
   print "fast server\n";
 }
 else
 {
   print "slow server\n";
 }

Here is a simple example showing how you can post an entry to your 
LiveJournal:

 use strict;
 use warnings;
 use WebService::LiveJournal;
 
 print "user: ";
 my $user = <STDIN>;
 chomp $user;
 print "pass: ";
 my $password = <STDIN>;
 chomp $password;
 
 my $client = WebService::LiveJournal->new(
   server => 'www.livejournal.com',
   username => $user,
   password => $password,
 );
 
 print "subject: ";
 my $subject = <STDIN>;
 chomp $subject;
 
 print "content: (^D or EOF when done)\n";
 my @lines = <STDIN>;
 chomp @lines;
 
 my $event = $client->create(
   subject => $subject,
   event => join("\n", @lines),
 );
 
 $event->update;
 
 print "posted $event with $client\n";
 print "itemid = ", $event->itemid, "\n";
 print "url    = ", $event->url, "\n";
 print "anum   = ", $event->anum, "\n";

Here is an example of a script that will remove all entries from a 
LiveJournal.  Be very cautious before using this script, once the 
entries are removed they cannot be brought back from the dead:

 use strict;
 use warnings;
 use WebService::LiveJournal;
 
 print "WARNING WARNING WARNING\n";
 print "this will remove all entries in your LiveJournal account\n";
 print "this probably cannot be undone\n";
 print "WARNING WARNING WARNING\n";
 
 print "user: ";
 my $user = <STDIN>;
 chomp $user;
 print "pass: ";
 my $password = <STDIN>;
 chomp $password;
 
 my $client = WebService::LiveJournal->new(
   server => 'www.livejournal.com',
   username => $user,
   password => $password,
 );
 
 print "$client\n";
 
 my $count = 0;
 while(1)
 {
   my $event_list = $client->get_events('lastn', howmany => 50);
   last unless @{ $event_list } > 0;
   foreach my $event (@{ $event_list })
   {
     print "rm: ", $event->subject, "\n";
     $event->delete;
     $count++;
   }
 }
 
 print "$count entries deleted\n";

Here is a really simple command line interface to the LiveJournal
admin console.  Obvious improvements like better parsing of the commands
and not displaying the password are left as an exercise to the reader.

 use strict;
 use warnings;
 use WebService::LiveJournal;
 
 my $client = WebService::LiveJournal->new(
   server => 'www.livejournal.com',
   username => do {
     print "user: ";
     my $user = <STDIN>;
     chomp $user;
     $user;
   },
   password => do {
     print "pass: ";
     my $pass = <STDIN>;
     chomp $pass;
     $pass;
   },
 );
 
 while(1)
 {
   print "> ";
   my $command = <STDIN>;
   unless(defined $command)
   {
     print "\n";
     last;
   }
   chomp $command;
   $client->batch_console_commands(
     [ split /\s+/, $command ],
     sub {
       foreach my $line (@_)
       {
         my($type, $text) = @$line;
         printf "%8s : %s\n", $type, $text;
       }
     }
   );
 }

=head1 HISTORY

The code in this distribution was written many years ago to sync my website
with my LiveJournal.  It has some ugly warts and its interface was not well 
planned or thought out, it has many omissions and contains much that is apocryphal 
(or at least wildly inaccurate), but it (possibly) scores over the older 
LiveJournal modules on CPAN in that it has been used in production for 
many many years with very little maintenance required, and at the time of 
its original writing the documentation for those modules was sparse or misleading.

=head1 SEE ALSO

=over 4

=item

L<http://www.livejournal.com/doc/server/index.html>,

=item

L<Net::LiveJournal>,

=item

L<LJ::Simple>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
