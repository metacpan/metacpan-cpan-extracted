package WWW::BF2S;

our $VERSION = '0.03';

use XML::Simple;
use Data::Dumper;
use LWP::Simple;

sub new {
  my $class = shift;
  my %options = @_;
  my $self = {};
  bless($self, $class); # class-ify it.

  $self->{debugLog} = $options{DebugLog} || 'debug.log';
  $self->{debugLevel} = $options{DebugLevel} || 0;
  $self->{storeFile} = $options{StoreFile} || 'stats.xml';

  eval { $self->{store} = XMLin($self->{storeFile}); }; # read in store XML data (it's okay if it fails/doesn't exist, I think)

  $self->__debug(7, 'Object Attributes:', Dumper($self));

  return $self;
}

sub __debug {
  my $self = shift || return undef;
  return undef unless $self->{debugLog}; # skip unless log file is defined
  my $level = int(shift);
  return undef unless $self->{debugLevel} >= $level; # skip unless log level is as high as this item
  if (open(BF2SDEBUG, ">>$self->{debugLog}")) {
    my $time = localtime();
    foreach my $group (@_) { # roll through many items if they are passed in as an array
      foreach my $line (split(/\r?\n/, $group)) { # roll through items that are multiline, converting to multiple separate lines
        print BF2SDEBUG "[$time] $line\n";
      }
    }
    close(BF2SDEBUG);
  }
  return undef;
}

sub __fetchData {
  my $self = shift || return undef;

  my $urlBase = 'http://bf2s.com/xml.php?pids=';
  my $pidList = {};
  foreach my $pid (@_) {
    next if ($pid =~ m|[^0-9]|); # check for validity
    next if ($self->{store}->{'pid'.$pid}->{updated} + 7200 > time()); # make sure the cached copy is old enough (2 hours)
    $pidList->{$pid}++; # add it to the queue
  }
  $self->__debug(6, 'PIDS REQUESTED:', keys(%{$pidList}));

  my @candidates;
  # TODO: make a list of candidates from the data store (even ones we're not asking for) in order of best to worst

  while (scalar(keys(%{$pidList})) < 64) { # if the request list is shorter than 64 pids (the max per request), we should add more from the cache that need refreshed instead of wasting the opportunity
    my $candidate = shift(@candidates) || last; # get the next candidate from the list (or exit the loop because we've run out of candidates)
    next if ($pidList->{$candidate}); # if it's already in the list, skip it
    $pidList->{$candidate}++; # seems okay, add it to the pidList
  }
  $self->__debug(6, 'PIDS WITH AUTO:', keys(%{$pidList}));
  my $pids = join(',', sort(keys(%{$pidList}))); # join the queue in a proper format

  return $response unless $pids; # only proceed if there is something to fetch

  my $response = get($urlBase.$pids); # fetch the data from the source (bf2s feed)
  #use IO::All; my $response; $response < io('test.xml'); # for testing only (an XML file that has a sample of raw returned data from the feed source)
  return undef unless $response; # if it failed, don't continue

  my $parsedResponse = XMLin($response); # parse the XML into a hashref
  $self->__debug(7, 'PARSEDRESPONSE:', Dumper($parsedResponse));

  $parsedResponse->{player} = $self->__forceArray($parsedResponse->{player});

  my $stats = {};
  foreach my $player (@{$parsedResponse->{player}}) { # store in a normalized structure
    next unless ($pidList->{$player->{pid}}); # probably not necessary, but don't parse things we didn't ask for
    $player->{updated} = time();
    $stats->{$player->{pid}} = $player;
  }
  $self->__debug(7, 'NORMALIZEDRESPONSE:', Dumper($stats));
  $self->__injectIntoDataStore($stats);

  return $stats; # return the response content
}

sub __forceArray {
  my $self = shift;
  my $input = shift;
  return $input if (ref($input) eq 'ARRAY'); # return if already an arrayref
  my $output;
  $output->[0] = $input; # force it to be an item in an arrayref
  return $output; # return the arrayref
}

sub __injectIntoDataStore {
  my $self = shift;
  my $stats = shift;

  foreach my $pid (keys(%{$stats})) {
    next if ($pid =~ m|[^0-9]|); # ensure only numerical pids (is this necessary?)
    $self->{store}->{'pid'.$pid} = $stats->{$pid}; # insert/replace into data store
  }

  my $storeOut = XMLout($self->{store}); # convert hashref data into XML structure
  if ($storeOut) { # only if storeOut is valid/existing (wouldn't want to wipe out our only cache/store with null)
    if (open(STOREFH, '>'.$self->{storeFile})) { # overwrite old store file with new store file
      print STOREFH $storeOut;
      close(STOREFH);
    }
  }

  return undef;
}

sub getStats {
  my $self = shift;
  my @pids = @_;
  my $stats = {};

  $self->__fetchData(@pids); # get fresh data when if necessary

  foreach my $pid (@pids) { # prep the requested data for return
    $stats->{$pid} = $self->{store}->{'pid'.$pid};
  }

  return $stats; # return the requested data
}

1;

__END__

=head1 NAME

WWW::BF2S - Get Battlefield 2 Player Stats

=head1 SYNOPSIS

  use WWW::BF2S;
  my $bf2 = Net::BF2S->new;
  my $data = $bf2->getStats(45355493,64573414,64318788,64246757,62797217,61091442,64964638,64661842,65431962,58968459);

=head1 DESCRIPTION

Fetches Battlefield 2 player stats from BF2S.

You must use the PID (player ID) when requesting stats.  If you try to request the player stats by player name, the module will ignore it and move on to the next one in the list.  You can get the PID from many sources, including the BF2S.com website.

You can only make THREE requests for data in a SIX hour period.  This is a restriction from the feed provider, not the module.  Try to ask for as many PIDs as possible in one request.  The module is being written (this part is coming soon) in a way that will try to include a list of "PID Request Candidates" (a list of PIDs that you've asked for before, but you didn't ask for this time around) that will also be requested in that same request, which is meant to update your local player Stat Cache when possible.

I'll provide more documentation later.

=head2 getStats

Access this method in an OO way.

  my $data = $bf2->getStats(65431962,64246757,64661842);

It will return a hashref that contains data for the PIDs requested.  It is in this format:

  $data = {
             '65431962' => {
                            'country' => 'US',
                            'link' => 'http://bf2s.com/player/65431962/',
                            'time' => '525400',
                            'deaths' => '5332',
                            'nick' => 'Rd54321',
                            'score' => '9757',
                            'wins' => '222',
                            'losses' => '368',
                            'pid' => '65431962',
                            'updated' => 1148275361,
                            'rank' => '6',
                            'kills' => '3237'
                          },
            '64246757' => {
                            'country' => 'US',
                            'link' => 'http://bf2s.com/player/64246757/',
                            'time' => '272092',
                            'deaths' => '1739',
                            'nick' => 'dustyheynu',
                            'score' => '5076',
                            'wins' => '76',
                            'losses' => '110',
                            'pid' => '64246757',
                            'updated' => 1148275361,
                            'rank' => '5',
                            'kills' => '1130'
                          },
            '64661842' => {
                            'country' => 'US',
                            'link' => 'http://bf2s.com/player/64661842/',
                            'time' => '1008165',
                            'deaths' => '11902',
                            'nick' => 'READYORNOTHEREICOME',
                            'score' => '29062',
                            'wins' => '550',
                            'losses' => '689',
                            'pid' => '64661842',
                            'updated' => 1148275361,
                            'rank' => '8',
                            'kills' => '8757'
                          }
          };

It will only fetch data that is at least two hours old.  Otherwise, it will serve the data from the stat cache file.

If none of the PIDs need updated (already updated within two hours), it won't send a request at all and only serve from the cache.

If at least one of the PIDs need updated (because it's older than two hours or has never been requested), it will request those PIDs that need updated.  When the "PID Request Candidates" feature is ready, it will also request, at that same time, a list of "candidates" from your stat cache.

=head2 BF2S Data Source Restrictions

Because the BF2S data source limits a single IP address to only three requests in a six hours, each request needs to be used properly.  Basically, you can only make a request once every two hours.  The PID Request Candidates feature is here to help, or at least try.

For each request, data for a maximum of 64 PIDs will be returned.

=head2 Stats Cache

The Stats Cache (stored locally automatically) collects, combines, and stores results from every request made to the BF2S data source.  If used properly, you can use this module to make requests as often as you wish (used directly on a website, for example), and unless the data in the cache has reached a certain age, every request can be served via the Stats Cache.  This means that you can let this module handle the caching and you can use it as if you were asking a live source each time.

=head2 PID Request Candidates

(This is a feature that is not yet included.  It is top priority and should be added to the next update.)

To make the most of the Stats Cache, every time the module deems it necessary to make a request out to the BF2S data source, it also includes, in addition to the requested PIDs, a list of other PIDs found in the Stats Cache that could be updated.

If less than the maximum number of PIDs are being requested by your application, it will include as many PIDs from your Stats Cache as possible (max 64 total).  It will add those in order of needing-updated-ness.  If your number of requested PIDs and the total size of your Stats Cache is smaller than the 64 max, it will just refresh your entire Stats Cache as well as include any new PIDs that weren't already in your cache.

The getStats method will still only return the PIDs you requested.  This feature will simply update your cached PIDs at the same time.

=head1 SEE ALSO

Uses data feed from Jeff Minard's BF2S MyLeaderBoard API E<lt>http://jrm.cc/extras/mlb/readme.htmlE<gt>.

=head1 TODO

Need to finish the PID Request Candidates list functionality.

=head1 CHANGES

  0.03 - Mon May 22 20:26:34 UTC 2006 - Dusty Wilson
  Renamed to WWW:BF2S (was Net::BF2S).
    Updated module package name.
    Updated documentation.

  0.02 - Mon May 22 05:34:05 UTC 2006 - Dusty Wilson
  Modified documentation:
    Fixed documentation bugs (exposed E<lt>gtE<gt>).
    Added information about the getData method.
    Added information about the BF2S Data Source Restrictions.
    Added information about the Stats Cache.
    Added information about the PID Request Candidates.

  0.01 - Sun May 21 21:52:31 UTC 2006 - Dusty Wilson
  New module with basic functionality.

=head1 BUGS

There probably are some.  Let me know what you find.

=head1 AUTHOR

Dusty Wilson, E<lt>bf2s-module@dusty.hey.nuE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dusty Wilson E<lt>http://dusty.hey.nu/E<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
