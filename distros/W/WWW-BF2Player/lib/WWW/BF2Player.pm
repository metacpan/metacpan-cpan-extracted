package WWW::BF2Player;

our $VERSION = '0.01';

use XML::Simple;
use Data::Dumper;
use LWP::Simple;
use Hey::Common;
use Hey::Cache;

=cut

=head1 NAME

WWW::BF2Player - Fetch information about game servers from BF2Player.com

=head1 SYNOPSIS

  # example 1
  use WWW::BF2Player;
  my $bfp = WWW::BF2Player->new; # omitted UserId, must set it per-request
  my $player = $bfp->getPlayer( UserId => '5307', PlayerId => '64246757' ); # userId specified per-request
   
  # example 2
  use WWW::BF2Player;
  my $bfp = WWW::BF2Player->new( UserId => '5307' ); # set a default UserId, can omit UserId per-request
  my $player = $bfp->getPlayer( PlayerId => '64246757' ); # use the default UserId

=head1 DESCRIPTION

First, you must have an account (free) at BF2Player.com to make use of this module.  Second, you must create and populate a buddy list on their site.  You can only use this module to ask for information about players in your buddy list.  This is a restriction on their part to prevent you from asking information for too many players.  I guess to prevent you from competing and wasting their resources.  Understandable, I suppose. 

=head2 new

  my $gm = WWW::BF2Player->new; # no options or defaults specified
  
  my $gm = WWW::BF2Player->new( UserId => '5307' ); # default to a certain UserId

You can specify several options in the constructor.

  my $gm = WWW::BF2Player->new(
      Expires => 300,
      UserId => '5307',
      CacheFile => 'my_player_cache.xml',
      DebugLog => 'my_debug_log.txt',
      DebugLevel => 3,
  );

=head3 Expires [optional]

Sets the data cache freshness in seconds.  If the cache has data older than this number of seconds, it is no longer valid.  It's best that 
you set this value to something higher than 1 minute and would be even better if you were satisfied with setting it around 5 minutes.  If 
the cache is fresh enough, it won't even ask the Game-Monitor.com server for any information.  Keep in mind that Game-Monitor doesn't update 
their information more than once every several minutes.  It won't be useful for you to set the Expires value too low.

=head3 UserId [optional]

Sets the default UserId use.  If you don't specify a UserId when asking for data, it will use this value instead.  You have to specify it somewhere (here or per-request) or it won't work.

=head3 CacheFile [optional]

Sets the path and filename for the data cache.  This is "bf2PlayerCache.xml" by default.

=head3 DebugLog [optional]

Sets the path and filename for the debug log.  This is "bf2PlayerDebug.log" by default.  To enable logging, you'll have to choose a DebugLevel 
greater than zero (zero is default).

=head3 DebugLevel [optional]

Sets the level of debugging.  The larger the number, the more verbose the logging.  This is zero by default, which means no logging at all.

=cut

sub new {
  my $class = shift;
  my %options = @_;
  my $self = {};
  bless($self, $class); # class-ify it.

  $self->{fxn} = Hey::Common->new;

  $self->{debugLog} = $options{DebugLog} || 'bf2PlayerDebug.log';
  $self->{debugLevel} = $options{DebugLevel} || 0;

  $self->{cache} = Hey::Cache->new(
				Namespace => $options{Namespace} || $options{NameSpace} || 'WWW::BF2Player',
				CacheFile => $options{CacheFile} || $options{StoreFile} || 'bf2PlayerCache.xml',
				Expires => $options{Expires} || $options{Fresh} || 600,
			 );

  $self->{userId} = $options{UserId} || undef;

  $self->__debug(7, 'Object Attributes:', Dumper($self));

  return $self;
}

sub __debug {
  my $self = shift || return undef;
  return undef unless $self->{debugLog}; # skip unless log file is defined
  my $level = int(shift);
  return undef unless $self->{debugLevel} >= $level; # skip unless log level is as high as this item
  if (open(BF2PLAYERDEBUG, ">>$self->{debugLog}")) {
    my $time = localtime();
    foreach my $group (@_) { # roll through many items if they are passed in as an array
      foreach my $line (split(/\r?\n/, $group)) { # roll through items that are multiline, converting to multiple separate lines
        print BF2PLAYERDEBUG "[$time] $line\n";
      }
    }
    close(BF2PLAYERDEBUG);
  }
  return undef;
}

sub __fetchPlayerInfo {
  my $self = shift || return undef;
  my %options = @_;
  my $userId = $options{UserId} || $self->{userId} || return undef; # if the UserId isn't defined, fail
  my $playerId = $options{PlayerId} || return undef; # if the PlayerId isn't defined, fail

  my $cache = $self->{cache}->get( Name => $playerId ); # get data from cache
  if ($cache) { # cache data exists for this host/port
    $self->__debug(3, 'Cache data is fresh.');
    return $cache if ($VERSION eq $cache->{client_version}); ## check the client version against the cache, in case the client (this code) has been upgraded, which might break the cache
  }
  else {
    $self->__debug(2, 'Cache is not fresh or no data.  Fetching from source.');
  }

  my $url = qq(http://www.bf2player.com/index.php?page=xml&id=$userId&pid=$playerId); # format the url for the source
  my $response = get($url); # fetch the info from the source
  unless ($response) { # it failed (rejected, bad connection, etc)
    $self->__debug(2, 'Could not fetch data from source.');
    if ($store) {
      $self->__debug(2, 'Going to provide stale store data instead of failing.');
      return $self->{cache}->get( Name => $playerId, Expires => 99999999 ); # get data from cache with no expiration
    }
    else { # there is nothing to send back, fail
      $self->__debug(3, 'There is no store data to return.');
      return undef;
    }
  }
  my $data = XMLin($response, KeyAttr => undef); # parse the xml into hashref

  $data->{client_version} = $VERSION;

  $self->{cache}->set( Name => $playerId, Value => $data ); # store it, baby!

  return $data;
}

=cut

=head2 getPlayerRaw

  my $player = $gm->getPlayerRaw( PlayerId => '64246757' ); # omitted UserId, use the UserId specified in the constructor  
  my $player = $gm->getPlayerRaw( UserId => '5307', PlayerId => '64246757' ); # specified UserId, use a different UserId

This fetches the player data from the BF2Player.com server.  It's returned as-is from the server, so the data isn't pretty, but it's technically accurate.  If you just want the raw data, this is the function for you.  If you want it prettified a bit, getPlayer might be a better fit.  See also getPlayer.

=head3 UserId [optional]

If you specify it here, it overrides what was set in the constructor.  If you didn't specify it in the constructor, it is required here.

=head3 PlayerId [required]

Which PlayerId to ask about.  This is their official Battlefield 2 PID, not their username.

=cut

sub getPlayerRaw {
  my $self = shift || return undef;
  my %options = @_;
  my $userId = $options{UserId} || $self->{userId} || return undef; # if the UserId isn't defined, get the default or fail
  my $playerId = $options{PlayerId} || return undef; # if the PlayerId isn't defined, fail
  my $data = $self->__fetchPlayerInfo( UserId => $userId, PlayerId => $playerId ); # fetch it!
  return $data; # return the post-processed player info
}

=cut

=head2 getPlayer

  my $player = $gm->getPlayer( PlayerId => '64246757' ); # omitted UserId, use the UserId specified in the constructor  
  my $player = $gm->getPlayer( UserId => '5307', PlayerId => '64246757' ); # specified UserId, use a different UserId

This is the same thing as getPlayerRaw, except it prettifies the returned data.  See also getPlayerRaw.

=head3 UserId [optional]

If you specify it here, it overrides what was set in the constructor.  If you didn't specify it in the constructor, it is required here.

=head3 PlayerId [required]

Which PlayerId to ask about.  This is their official Battlefield 2 PID, not their username.

=cut

sub getPlayer {
  my $self = shift || return undef;
  my $data = $self->getPlayerRaw(@_); # fetch the data first

  my $key = {
    army => {
      0 => "USMC",
      1 => "MEC",
      2 => "China",
      3 => "US Navy SEAL",
      4 => "British SAS",
      5 => "Russian Spetsnaz",
      6 => "MEC SF",
      7 => "Rebels",
      8 => "Insurgent",
      9 => "European Union",
      avg => "Average",
      total => "Total",
    },
    equipment => {
      1 => "C4",
      2 => "Claymore",
      3 => "Hand Grenade",
      5 => "AT Mine",
      avgexp => "Avg Explosive",
      totalexp => "Total Explosive",
      6 => "Flashbang / Tear Gas",
      7 => "Grappling Hook",
      8 => "Zip Line",
      avgtac => "Avg Tactical",
      totaltac => "Total Tactical ",
      0 => "Knife",
      4 => "Defibrillator",
      avgwea => "Avg Weapons",
      totalwea => "Total Weapons",
    },
    expansion => {
      0 => "Original BF2",
      1 => "Special Forces",
      2 => "European Union",
    },
    kit => {
      0 => "Anti-tank",
      1 => "Assault",
      2 => "Engineer",
      3 => "Medic",
      6 => "Sniper",
      4 => "Spec-Ops",
      5 => "Support",
      avg => "Average",
      total => "Total",
    },
    map => {
      101 => "Dalian Plant",
      100 => "Daqing Oilfields",
      102 => "Dragon Valley",
      103 => "FuShe Pass",
      6 => "Gulf of Oman",
      0 => "Kubra Dam",
      1 => "Mashtuur City",
      2 => "Operation Clean Sweep",
      5 => "Sharqi Peninsula",
      105 => "Songhua Stalemate",
      4 => "Strike at Karkand",
      3 => "Zatar Wetlands",
      601 => "Wake Island",
      300 => "Devils Perch",
      307 => "Ghost Town",
      304 => "Leviathan",
      305 => "Mass Destruction",
      302 => "Night Flight",
      306 => "Surge",
      301 => "The Iron Gator",
      303 => "Warlord",
      110 => "Great Wall",
      10 => "Operation Smoke Screen",
      11 => "Taraba Quarry",
      avg => "Average",
      total => "Total",
    },
    rank => {
      0 => "Private",
      1 => "Private First Class",
      2 => "Lance Corporal",
      3 => "Corporal",
      4 => "Sergeant",
      5 => "Staff Sergeant",
      6 => "Gunnery Sergeant",
      7 => "Master Sergeant",
      8 => "First Sergeant",
      9 => "Master Gunnery Sergeant",
      10 => "Sergeant Major",
      11 => "Sergeant Major of the Corps",
      12 => "Second Lieutenant",
      13 => "First Lieutenant",
      14 => "Captain",
      15 => "Major",
      16 => "Lieutenant Colonel",
      17 => "Colonel",
      18 => "Brigidier General",
      19 => "Major General",
      20 => "Lieutenant General",
      21 => "General",
    },
    theater => {
      0 => "USMC",
      1 => "MEC",
      2 => "China",
      3 => "US Navy SEAL",
      4 => "British SAS",
      5 => "Russian Spetsnaz",
      6 => "MEC SF",
      7 => "Rebels",
      8 => "Insurgent",
      9 => "European Union",
    },
    unlock => {
      11 => "DAO-12",
      22 => "G3",
      33 => "Jackhammer",
      44 => "L85A1",
      55 => "G36C",
      66 => "PKM",
      77 => "M95",
      88 => "F2000",
      99 => "MP7",
      111 => "G36E",
      222 => "SCAR-L",
      333 => "MG36",
      444 => "P90",
      555 => "L96A1",
    },
    vehicle => {
      0 => "Armor",
      1 => "Aviator",
      2 => "Air Defense",
      6 => "Ground Defense",
      3 => "Helicopter",
      4 => "Transport",
      avg => "Average",
      total => "Total",
    },
    weapon => {
      0 => "Assault Rifle",
      6 => "AT/AA",
      2 => "Carbines",
      10 => "Defibrillator",
      11 => "Explosives",
      12 => "Grenade",
      1 => "Grenade Launcher",
      9 => "Knife",
      3 => "Lt Machine Gun",
      5 => "Pistol",
      8 => "Shotgun",
      4 => "Sniper Rifle",
      7 => "Submachine Gun",
      13 => "Zip Line",
      avg => "Average",
      total => "Total",
    },
    badge => {
      1031120 => "Anti-Tank Combat",
      1031119 => "Assault Combat",
      1031105 => "Engineer Combat",
      1031113 => "Medic Combat",
      1031109 => "Sniper Combat",
      1031115 => "Spec-Ops Combat",
      1031121 => "Support Combat",
      1032415 => "Explosives Ordinance",
      1031406 => "Knife Combat",
      1031619 => "Pistol Combat",
      1190304 => "Command",
      1190507 => "Engineer",
      1190601 => "First Aid",
      1191819 => "Resupply",
      1220104 => "Air Defense",
      1220118 => "Armor",
      1220122 => "Aviator",
      1031923 => "Ground Defense",
      1220803 => "Helicopter",
      1222016 => "Transport",
      1261120 => "Anti-Tank Specialist",
      1261119 => "Assault Specialist",
      1261105 => "Engineer Specialist",
      1261113 => "Medic Specialist",
      1261109 => "Sniper Specialist",
      1261115 => "Spec-Ops Specialist",
      1261121 => "Support Specialist",
      1260708 => "Grappling Hook",
      1260602 => "Tactical Support Weaponry",
      1262612 => "Zip Line Specialist",
    },
    medal => {
      2051907 => "Gold Star",
      2051919 => "Silver Star",
      2051902 => "Bronze Star",
      2191608 => "Purple Heart",
      2020903 => "Combat Infantry",
      2020913 => "Marksman Infantry",
      2020919 => "Sharpshooter Infantry",
      2021403 => "Navy Cross",
      2020719 => "Golden Scimitar",
      2021613 => "Peoples Medallion",
      2190309 => "Air Combat",
      2190318 => "Armor Combat",
      2190303 => "Combat Action",
      2020419 => "Distinguished Service",
      2190703 => "Good Conduct",
      2190308 => "Helicopter Combat",
      2021322 => "Medal of Valor",
      2191319 => "Meritorious Service",
      2261919 => "British SAS Special Service",
      2260914 => "Insurgent Forces Special Service",
      2261303 => "MEC SF Special Service",
      2261802 => "Rebels Special Service",
      2261613 => "Russian Spetsnaz Special Service",
      2261913 => "U.S. Navy SEAL Special Service",
      2270521 => "European Union Special Service",
    },
    ribbon => {
      3190105 => "Aerial Service",
      3040109 => "Air Defense",
      3240102 => "Airborne",
      3190118 => "Armored Service",
      3240301 => "Combat Action",
      3190318 => "Crew Service",
      3190409 => "Distinguished Service",
      3190605 => "Far East Service",
      3240703 => "Good Conduct",
      3040718 => "Ground Defense",
      3190803 => "Helicopter Service",
      3150914 => "Infantry Officer",
      3241213 => "Legion of Merit",
      3211305 => "Meritorious Unit",
      3191305 => "Mid-East Service",
      3151920 => "Staff Officer",
      3212201 => "Valorous Unit",
      3242303 => "War College",
      3260105 => "Aerial Specialist",
      3260118 => "Armored Specialist",
      3261901 => "British SAS Service",
      3260318 => "Crew Specialist",
      3260803 => "Helicopter Specialist",
      3260914 => "Insurgent Forces Service",
      3261319 => "MEC Special Forces Service",
      3261805 => "Rebels Service",
      3261819 => "Russian Spetsnaz Service",
      3261919 => "U.S. Navy SEAL Service",
      3270519 => "European Union Service",
    },
  };

  my $stats = {};
  foreach my $stat (sort(keys(%{$data->{stats}}))) {
    my $target = $stats;
    my @split = split(/_/, $stat);
    my $category = $split[0];
    while (my $split = shift(@split)) {
      $target->{$split} = $target->{$split} || {};
      if (!$split[0] && $split[0] ne '0') {
        $target->{$split} = $data->{stats}->{$stat};
      }
      if ($split =~ m|^\d+$|) {
        if ($key->{$category}->{$split}) {
          $target->{$split}->{name} = $key->{$category}->{$split};
        }
      }
      $target = $target->{$split};
    }
  }

  $data->{stats} = $stats; # overwrite the ugly with the pretty

  return $data; # return the post-processed player info
}

=cut

=head1 AUTHOR

Dusty Wilson, E<lt>www-bf2player-module@dusty.hey.nuE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dusty Wilson E<lt>http://dusty.hey.nu/E<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
