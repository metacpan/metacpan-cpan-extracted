package WWW::GameMonitor;

our $VERSION = '0.03';

use XML::Simple;
use Data::Dumper;
use LWP::Simple;
use Hey::Common;
use Hey::Cache;

=cut

=head1 NAME

WWW::GameMonitor - Fetch information about game servers from Game-Monitor.com

=head1 SYNOPSIS

  # example 1
  use WWW::GameMonitor;
  my $gm1 = WWW::GameMonitor->new;
  my $serv1 = $gm1->getServerInfo( Host => '216.237.126.132', Port => '16567' ); # ACE Battlefield2 Server
  print qq(On $serv1->{name}, $serv1->{count}->{current} players ($serv1->{count}->{max} limit) are playing $serv1->{game}->{longname}, map $serv1->{map}.\n);
  
  # example 2
  use WWW::GameMonitor;
  my $gm2 = WWW::GameMonitor->new( Host => '216.237.126.132', Port => '16567' ); # default to a certain server
  my $serv2 = $gm2->getServerInfo; # uses the defaults specified in the constructor

=head1 DESCRIPTION

This module will help you get information about various official and clan game servers (Battlefield 2, Quake 4, and many more).  The server 
that is being queried must be listed as a "premium" server.  This means someone (you, the server owner, or someone else) must have an active 
subscription with Game-Monitor.com for that server to be accessible in this way.  You, yourself, do not have to have an account with them, but 
someone out there on the Internet must have listed that specific server in their paid account.  For example, at the time of writing, the ACE 
Battlefield 2 server E<lt>http://www.armchairextremist.com/E<gt> is listed under such an account.  This means that you could, without needing 
to contact or pay anyone, use this module to ask for information about the ACE Battlefield 2 server.  If you run your own clan game server or 
you want to monitor someone else's game server (and Game-Monitor.com supports your game), it might be worth it to you to pay them the 
~USD$3-7/month for this ability.  They take PayPal.

=head2 new

  my $gm = WWW::GameMonitor->new; # no options or defaults specified
  
  my $gm = WWW::GameMonitor->new( Host => '216.237.126.132', Port => '16567' ); # default to a certain server

You can specify several options in the constructor.

  my $gm = WWW::GameMonitor->new(
      Expires => 300,
      Host => '216.237.126.132',
      Port => '16567',
      CacheFile => 'my_gm_cache.xml',
      DebugLog => 'my_debug_log.txt',
      DebugLevel => 3,
      UID => 12345,
      List => 0,
  );

=head3 Expires [optional]

Sets the data cache freshness in seconds.  If the cache has data older than this number of seconds, it is no longer valid.  It's best that 
you set this value to something higher than 1 minute and would be even better if you were satisfied with setting it around 5 minutes.  If 
the cache is fresh enough, it won't even ask the Game-Monitor.com server for any information.  Keep in mind that Game-Monitor doesn't update 
their information more than once every several minutes.  It won't be useful for you to set the Expires value too low.

=head3 Host [optional]

Sets the default host to ask about.  If you don't specify a host when asking for data, it will use this value instead.

=head3 Port [optional]

Sets the default port to ask about.  If you don't specify a port when asking for data, it will use this value instead.

=head3 CacheFile [optional]

Sets the path and filename for the data cache.  This is "gameServerInfoCache.xml" by default.

=head3 DebugLog [optional]

Sets the path and filename for the debug log.  This is "gmDebug.log" by default.  To enable logging, you'll have to choose a DebugLevel 
greater than zero (zero is default).

=head3 DebugLevel [optional]

Sets the level of debugging.  The larger the number, the more verbose the logging.  This is zero by default, which means no logging at all.

=head3 UID [optional]

Sets the default UID used for fetching buddy lists.

=head3 List [optional]

Sets the default buddy list used for fetching buddy lists.

=cut

sub new {
  my $class = shift;
  my %options = @_;
  my $self = {};
  bless($self, $class); # class-ify it.

  $self->{fxn} = Hey::Common->new;

  $self->{debugLog} = $options{DebugLog} || 'gmDebug.log';
  $self->{debugLevel} = $options{DebugLevel} || 0;

  $self->{cache} = Hey::Cache->new(
				Namespace => $options{Namespace} || $options{NameSpace} || 'WWW::GameMonitor',
				CacheFile => $options{CacheFile} || $options{StoreFile} || 'gameServerInfoCache.xml',
				Expires => $options{Expires} || $options{Fresh} || 600,
			 );

  $self->{host} = $options{Host} || undef;
  $self->{port} = $options{Port} || undef;

  $self->{uid} = (defined($options{UID}) ? $options{UID} : 0);
  $self->{buddyList} = (defined($options{List}) ? $options{List} : 0);

  $self->__debug(7, 'Object Attributes:', Dumper($self));

  return $self;
}

sub __debug {
  my $self = shift || return undef;
  return undef unless $self->{debugLog}; # skip unless log file is defined
  my $level = int(shift);
  return undef unless $self->{debugLevel} >= $level; # skip unless log level is as high as this item
  if (open(GAMEMONDEBUG, ">>$self->{debugLog}")) {
    my $time = localtime();
    foreach my $group (@_) { # roll through many items if they are passed in as an array
      foreach my $line (split(/\r?\n/, $group)) { # roll through items that are multiline, converting to multiple separate lines
        print GAMEMONDEBUG "[$time] $line\n";
      }
    }
    close(GAMEMONDEBUG);
  }
  return undef;
}

sub __fetchServerInfo {
  my $self = shift || return undef;
  my %options = @_;
  my $host = $options{Host} || return undef; # if the host isn't defined, fail
  my $port = $options{Port} || return undef; # if the port isn't defined, fail

  my $name = $host.':'.$port;

  my $cache = $self->{cache}->get( Name => $name ); # get data from cache
  if ($cache) { # cache data exists for this host/port
    $self->__debug(3, 'Cache data is fresh.');
    return $cache if ($VERSION eq $cache->{client_version}); ## check the client version against the cache, in case the client (this code) has been upgraded, which might break the cache
  }
  else {
    $self->__debug(2, 'Cache is not fresh or no data.  Fetching from source.');
  }

  my $url = qq(http://www.game-monitor.com/client/server-xml.php?rules=1&ip=$host:$port); # format the url for the source
  my $response = get($url); # fetch the info from the source
  unless ($response) { # it failed (rejected, bad connection, etc)
    $self->__debug(2, 'Could not fetch data from source.');
    if ($store) {
      $self->__debug(2, 'Going to provide stale store data instead of failing.');
      return $self->{cache}->get( Name => $name, Expires => 99999999 ); # get data from cache with no expiration
    }
    else { # there is nothing to send back, fail
      $self->__debug(3, 'There is no store data to return.');
      return undef;
    }
  }
  my $data = XMLin($response, KeyAttr => undef); # parse the xml into hashref
  $data->{count} = $data->{players}; # move the player counts
  $data->{players} = $self->{fxn}->forceArray($data->{players}->{player}); # make sure players is an arrayref
  delete($data->{count}->{player}); # cleanup unnecessary stuff
  my $variables = $self->{fxn}->forceArray($data->{variables}->{variable}); # make sure variables is an arrayref
  delete($data->{variables}); # remove the messy looking and difficult to use variables structure

  foreach my $variable (@{$variables}) { # loop through the messy variables
    $data->{variables}->{$variable->{name}} = $variable->{value}; # make them pretty and easy to use
  }

  $data->{client_version} = $VERSION;

  $self->{cache}->set( Name => $name, Value => $data ); # store it, baby!

  return $data;
}

=cut

=head2 getServerInfo

  my $serv = $gm->getServerInfo; # uses the defaults specified in the constructor
  print qq(On $serv1->{name}, $serv1->{count}->{current} players ($serv1->{count}->{max} limit) are playing $serv1->{game}->{longname}, map $serv1->{map}.\n);
  
  my $serv = $gm->getServerInfo( Host => '216.237.126.132', Port => '16567' ); # ask about a certain server
  print qq(On $serv1->{name}, $serv1->{count}->{current} players ($serv1->{count}->{max} limit) are playing $serv1->{game}->{longname}, map $serv1->{map}.\n);

=head3 Host [required]

Asks about the specified host.  If this was specified in the constructor, this value is optional.

=head3 Port [required]

Asks about the specified port.  If this was specified in the constructor, this value is optional.

=cut

sub getServerInfo {
  my $self = shift || return undef;
  my %options = @_;
  my $host = $options{Host} || $self->{host} || return undef; # if the host isn't defined, get the default or fail
  my $port = $options{Port} || $self->{port} || return undef; # if the port isn't defined, get the default or fail
  my $data = $self->__fetchServerInfo( Host => $host, Port => $port ); # fetch it!
  return $data; # return the post-processed server info
}

=cut

=head2 getBuddyList

  $list = $gm->getBuddyList; # uses defaults set in the constructor
  $list = $gm->getBuddyList( List => 1 ); # sets a different list than the default
  $list = $gm->getBuddyList( UID => 12345, List => 2 ); # also sets a different UID along with a different list

=head3 UID [required]

Sets the UID used for fetching buddy lists.  If this was specified in the constructor, this value is optional.

=head3 List [required]

Sets the buddy list used for fetching buddy lists.  If this was specified in the constructor, this value is optional.

=cut

sub getBuddyList {
  my $self = shift || return undef;
  my %options = @_;

  $self->__debug(4, 'getBuddyList');

  my $uid = (defined($options{UID}) ? $options{UID} : (defined($self->{uid}) ? $self->{uid} : return undef));
  my $list = (defined($options{List}) ? $options{List} : (defined($self->{buddyList}) ? $self->{buddyList} : return undef));

  my $name = "BuddyList:${uid}:${list}"; # make a pretty name

  $self->__debug(4, 'getBuddyList('.$name.')');

  my $cache = $self->{cache}->get( Name => $name ); # get data from cache
  if ($cache) { # cache is still fresh
    $self->__debug(3, 'Cache data is fresh.');
    return $cache; # return the still fresh cache
  }
  else { # cache is stale
    $self->__debug(2, 'Cache is not fresh or no data.  Fetching from source.');
    my $url = qq(http://www.game-monitor.com/client/buddyList.php?uid=$uid&listid=$list&xml=1); # format the url for the source
    my $response = get($url); # fetch the info from the source
    if ($response) { # fetching from source succeeded
      my $data = XMLin($response, KeyAttr => undef); # parse the xml into hashref

      my $buddies = $self->{fxn}->forceArray($data->{buddy}); # make sure buddies is an arrayref
      delete($data->{buddy});
      foreach my $buddy (@{$buddies}) { # loop through the returned players
        if ($buddy->{server}->{fullip} eq '0.0.0.0:') { # no valid server, remove it
          $buddy->{server} = {}; # wipe it out
        }
        $data->{player}->{$buddy->{name}} = $buddy; # add this player to the list of players
      }

      $self->{cache}->set( Name => $name, Value => $data ); # store it away into the cache
      return $data; # return the new, fresh data
    }
    else { # fetching from source failed (rejected, bad connection, etc)
      $self->__debug(2, 'Could not fetch data from source.');
      $cache = $self->{cache}->get( Name => $name, Expires => 99999999 ); # get data from cache, ignoring expiration
      if ($cache) {
        $self->__debug(2, 'Going to provide stale cache data instead of failing.');
        return $cache; # return the old, stale cache
      }
      else {
        $self->__debug(3, 'There is no cache data to return.');
        return undef; # nothing to return
      }
    }
  }
  
}

=cut

=head1 AUTHOR

Dusty Wilson, E<lt>www-gamemonitor-module@dusty.hey.nuE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dusty Wilson E<lt>http://dusty.hey.nu/E<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
